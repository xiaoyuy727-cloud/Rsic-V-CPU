`ifdef VERILATOR
`include "include/common.sv"
`endif

//功能：输入dbus，输出dbus，把dbus的addr进行翻译。

module mmu import common ::*;(

    input logic clk,
    input logic reset,
    input logic flush,

    input  dbus_req_t  cpu_req,
    output dbus_resp_t cpu_resp,

    output dbus_req_t  mem_req,
    input  dbus_resp_t mem_resp,

    input logic [1:0] privil_mode,
    input logic [63:0] satp

);

    dbus_resp_t cpu_resp_r;
    dbus_resp_t cpu_resp_comb;

    assign cpu_resp = cpu_resp_comb;

    typedef enum logic [1:0] {
        KILL_NONE = 2'b00,
        KILL_ADDR = 2'b01,
        KILL_DATA = 2'b10
    } kill_state_t;

    kill_state_t kill_state;

    always_comb begin
        cpu_resp_comb = cpu_resp_r;

        if (kill_state == KILL_ADDR) begin
            cpu_resp_comb.addr_ok = 1'b1;
            cpu_resp_comb.data_ok = 1'b0;
            cpu_resp_comb.data    = 64'b0;
        end
        else if (kill_state == KILL_DATA) begin
            cpu_resp_comb.addr_ok = 1'b0;
            cpu_resp_comb.data_ok = 1'b1;
            cpu_resp_comb.data    = 64'b0;
        end
    end

    dbus_req_t cpu_req_eff;

    logic translate;
    dbus_req_t saved_req;

    logic [8:0] vpn2, vpn1, vpn0;
    logic [63:0] root_addr;
    logic [63:0] pte;
    logic [63:0] paddr;
    logic [63:0] pt_addr;
    logic [63:0] vaddr;

    always_comb begin
        cpu_req_eff = cpu_req;

        // flush 或 kill response 期间，不允许 MMU 接收旧路径请求
        if (flush || kill_state != KILL_NONE) begin
            cpu_req_eff.valid = 1'b0;
        end
    end

    assign translate = cpu_req_eff.valid
                     & (privil_mode != 2'b11)
                     & (satp[63:60] == 4'd8);

    assign vaddr = cpu_req_eff.addr;

    typedef enum logic [3:0] {
        IDLE    = 4'b0000,
        REQ_2   = 4'b0001,
        WAIT_2  = 4'b0010,
        REQ_1   = 4'b0011,
        WAIT_1  = 4'b0100,
        REQ_0   = 4'b0101,
        WAIT_0  = 4'b0110,
        REQ_P   = 4'b0111,
        WAIT_P  = 4'b1000
    } state_t;

    state_t cur;

    always_ff @(posedge clk) begin



    
        if (reset) begin
            cur        <= IDLE;
            cpu_resp_r <= '0;
            saved_req  <= '0;

            kill_state <= KILL_NONE;

            vpn2      <= 9'b0;
            vpn1      <= 9'b0;
            vpn0      <= 9'b0;
            root_addr <= 64'b0;
            pte       <= 64'b0;
            paddr     <= 64'b0;
            pt_addr   <= 64'b0;
        end
        else if (flush) begin
            cur        <= IDLE;
            cpu_resp_r <= '0;

            // 关键：
            // flush 当拍 instr_mem 在 redirect 分支，不会吃 data_ok。
            // 先给 arbiter addr_ok，下一拍再给 data_ok。
            kill_state <= cpu_req.valid ? KILL_ADDR : KILL_NONE;

            saved_req <= '0;

            vpn2      <= 9'b0;
            vpn1      <= 9'b0;
            vpn0      <= 9'b0;
            root_addr <= 64'b0;
            pte       <= 64'b0;
            paddr     <= 64'b0;
            pt_addr   <= 64'b0;



`ifdef DEBUG
            $display("[MMU FLUSH] drop cur=%0d saved_addr=%h cpu_valid=%b cpu_addr=%h priv=%0d satp=%h",
                     cur, saved_req.addr, cpu_req.valid, cpu_req.addr, privil_mode, satp);
`endif
        end
        else begin
            cpu_resp_r <= '0;

            if (kill_state == KILL_ADDR) begin
                kill_state <= KILL_DATA;
                cur <= IDLE;

`ifdef DEBUG
                $display("[MMU KILL ADDR] addr_ok to arbiter, cpu_valid=%b cpu_addr=%h",
                         cpu_req.valid, cpu_req.addr);
`endif
            end
            else if (kill_state == KILL_DATA) begin
                kill_state <= KILL_NONE;
                cur <= IDLE;

`ifdef DEBUG
                $display("[MMU KILL DATA] data_ok to arbiter/instr_mem, cpu_valid=%b cpu_addr=%h",
                         cpu_req.valid, cpu_req.addr);
`endif
            end
            else begin

`ifdef DEBUG
                if (mem_resp.data_ok) begin
                    if (cur == WAIT_2) begin
                        $display("[MMU L2] vaddr=%h root=%h vpn2=%h pte_addr=%h pte=%h next_pt=%h",
                                 saved_req.addr,
                                 root_addr,
                                 vpn2,
                                 root_addr + ({55'b0, vpn2} << 3),
                                 mem_resp.data,
                                 {8'b0, mem_resp.data[53:10], 12'b0});
                    end

                    if (cur == WAIT_1) begin
                        $display("[MMU L1] vaddr=%h pt_addr=%h vpn1=%h pte_addr=%h pte=%h next_pt=%h",
                                 saved_req.addr,
                                 pt_addr,
                                 vpn1,
                                 pt_addr + ({55'b0, vpn1} << 3),
                                 mem_resp.data,
                                 {8'b0, mem_resp.data[53:10], 12'b0});
                    end

                    if (cur == WAIT_0) begin
                        $display("[MMU L0] vaddr=%h pt_addr=%h vpn0=%h pte_addr=%h pte=%h final_paddr=%h",
                                 saved_req.addr,
                                 pt_addr,
                                 vpn0,
                                 pt_addr + ({55'b0, vpn0} << 3),
                                 mem_resp.data,
                                 {8'b0, mem_resp.data[53:10], saved_req.addr[11:0]});
                    end
                end
`endif

                case (cur)

                    IDLE: begin
                        if (cpu_req_eff.valid) begin
                            saved_req <= cpu_req_eff;

                            vpn2 <= cpu_req_eff.addr[38:30];
                            vpn1 <= cpu_req_eff.addr[29:21];
                            vpn0 <= cpu_req_eff.addr[20:12];

                            root_addr <= {8'b0, satp[43:0], 12'b0};

                            if (translate) begin
                                cur <= REQ_2;
                            end
                            else begin
                                paddr <= cpu_req_eff.addr;
                                cur   <= REQ_P;
                            end
                        end
                    end

                    REQ_2: begin
                        cur <= WAIT_2;
                    end

                    WAIT_2: begin
                        if (mem_resp.data_ok) begin
                            pte     <= mem_resp.data;
                            pt_addr <= {8'b0, mem_resp.data[53:10], 12'b0};
                            cur     <= REQ_1;
                        end
                    end

                    REQ_1: begin
                        cur <= WAIT_1;
                    end

                    WAIT_1: begin
                        if (mem_resp.data_ok) begin
                            pte     <= mem_resp.data;
                            pt_addr <= {8'b0, mem_resp.data[53:10], 12'b0};
                            cur     <= REQ_0;
                        end
                    end

                    REQ_0: begin
                        cur <= WAIT_0;
                    end

                    WAIT_0: begin
                        if (mem_resp.data_ok) begin
                            pte   <= mem_resp.data;
                            paddr <= {8'b0, mem_resp.data[53:10], saved_req.addr[11:0]};
                            cur   <= REQ_P;
                        end
                    end

                    REQ_P: begin
                        cur <= WAIT_P;
                    end

                    WAIT_P: begin
                        if (mem_resp.data_ok) begin
                            cpu_resp_r <= mem_resp;
                            cur        <= IDLE;
                        end
                    end

                    default: begin
                        cur <= IDLE;
                    end

                endcase
            end
        end
    end

    always_comb begin
        mem_req = '0;

        // flush 和 kill response 期间，绝对不能继续向内存发旧请求
        if (flush || kill_state != KILL_NONE) begin
            mem_req = '0;
        end
        else begin
            case (cur)

                REQ_2,WAIT_2: begin
                    mem_req.valid  = 1'b1;
                    mem_req.addr   = root_addr + ({55'b0, vpn2} << 3);
                    mem_req.size   = MSIZE8;
                    mem_req.strobe = 8'b0;
                    mem_req.data   = 64'b0;
                end

                REQ_1,WAIT_1: begin
                    mem_req.valid  = 1'b1;
                    mem_req.addr   = pt_addr + ({55'b0, vpn1} << 3);
                    mem_req.size   = MSIZE8;
                    mem_req.strobe = 8'b0;
                    mem_req.data   = 64'b0;
                end

                REQ_0,WAIT_0: begin
                    mem_req.valid  = 1'b1;
                    mem_req.addr   = pt_addr + ({55'b0, vpn0} << 3);
                    mem_req.size   = MSIZE8;
                    mem_req.strobe = 8'b0;
                    mem_req.data   = 64'b0;
                end

                REQ_P,WAIT_P: begin
                    mem_req      = saved_req;
                    mem_req.addr = paddr;
                end

                default: begin
                    mem_req = '0;
                end

            endcase
        end
    end


`ifdef DEBUG
always_ff @(posedge clk) begin
    if (!reset) begin
        if (mem_req.valid || mem_resp.addr_ok || mem_resp.data_ok) begin
            $display("[MMU_REQ] cur=%0d cpu_valid=%b cpu_addr=%h saved_valid=%b saved_addr=%h saved_strobe=%h | mem_valid=%b mem_addr=%h mem_strobe=%h mem_data=%h | addr_ok=%b data_ok=%b",
                     cur,
                     cpu_req_eff.valid, cpu_req_eff.addr,
                     saved_req.valid, saved_req.addr, saved_req.strobe,
                     mem_req.valid, mem_req.addr, mem_req.strobe, mem_req.data,
                     mem_resp.addr_ok, mem_resp.data_ok);
        end

        if ((cur == WAIT_2 || cur == WAIT_1 || cur == WAIT_0 || cur == WAIT_P) && mem_req.valid) begin
            $display("[MMU_WAIT_STILL_REQUESTING] cur=%0d mem_addr=%h strobe=%h data=%h addr_ok=%b data_ok=%b",
                     cur, mem_req.addr, mem_req.strobe, mem_req.data,
                     mem_resp.addr_ok, mem_resp.data_ok);
        end
    end
end
`endif

`ifdef DEBUG
always_ff @(posedge clk) begin
    if (!reset) begin
        if (cpu_resp.addr_ok || cpu_resp.data_ok || mem_resp.addr_ok || mem_resp.data_ok) begin
            $display("[MMU_RESP] cur=%0d saved_addr=%h mem_addr=%h mem_addr_ok=%b mem_data_ok=%b mem_data=%h | cpu_addr_ok=%b cpu_data_ok=%b cpu_data=%h",
                     cur, saved_req.addr, mem_req.addr,
                     mem_resp.addr_ok, mem_resp.data_ok, mem_resp.data,
                     cpu_resp.addr_ok, cpu_resp.data_ok, cpu_resp.data);
        end
    end
end
`endif



endmodule