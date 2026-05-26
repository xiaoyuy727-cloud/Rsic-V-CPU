`ifdef VERILATOR
`include "include/common.sv"
`endif

module mmu import common::*;(
    input  logic clk,
    input  logic reset,
    input  logic flush,

    input  dbus_req_t  cpu_req,
    output dbus_resp_t cpu_resp,

    output dbus_req_t  mem_req,
    input  dbus_resp_t mem_resp,

    input  logic [1:0]  privil_mode,
    input  logic [63:0] satp
);

    typedef enum logic [3:0] {
        IDLE   = 4'd0,
        REQ_2  = 4'd1,
        WAIT_2 = 4'd2,
        REQ_1  = 4'd3,
        WAIT_1 = 4'd4,
        REQ_0  = 4'd5,
        WAIT_0 = 4'd6,
        REQ_P  = 4'd7,
        WAIT_P = 4'd8,
        RESP   = 4'd9
    } state_t;

    typedef enum logic [1:0] {
        KILL_NONE = 2'b00,
        KILL_ADDR = 2'b01,
        KILL_DATA = 2'b10
    } kill_state_t;

    state_t      cur;
    kill_state_t kill_state;

    dbus_req_t  saved_req;
    dbus_resp_t saved_resp;

    logic [8:0]  vpn2, vpn1, vpn0;
    logic [63:0] root_addr;
    logic [63:0] pt_addr;
    logic [63:0] pte;
    logic [63:0] paddr;

    logic translate;

    assign translate = cpu_req.valid
                     && (privil_mode != 2'b11)
                     && (satp[63:60] == 4'd8);

    always_comb begin
        cpu_resp = '0;

        if (kill_state == KILL_ADDR) begin
            cpu_resp.addr_ok = 1'b1;
            cpu_resp.data_ok = 1'b0;
            cpu_resp.data    = 64'b0;
        end
        else if (kill_state == KILL_DATA) begin
            cpu_resp.addr_ok = 1'b0;
            cpu_resp.data_ok = 1'b1;
            cpu_resp.data    = 64'b0;
        end
        else if (cur == RESP) begin
            cpu_resp = saved_resp;
        end
    end

    always_comb begin
        mem_req = '0;

        if (!flush && kill_state == KILL_NONE) begin
            case (cur)
                REQ_2, WAIT_2: begin
                    mem_req.valid  = 1'b1;
                    mem_req.addr   = root_addr + ({55'b0, vpn2} << 3);
                    mem_req.size   = MSIZE8;
                    mem_req.strobe = 8'b0;
                    mem_req.data   = 64'b0;
                end

                REQ_1, WAIT_1: begin
                    mem_req.valid  = 1'b1;
                    mem_req.addr   = pt_addr + ({55'b0, vpn1} << 3);
                    mem_req.size   = MSIZE8;
                    mem_req.strobe = 8'b0;
                    mem_req.data   = 64'b0;
                end

                REQ_0, WAIT_0: begin
                    mem_req.valid  = 1'b1;
                    mem_req.addr   = pt_addr + ({55'b0, vpn0} << 3);
                    mem_req.size   = MSIZE8;
                    mem_req.strobe = 8'b0;
                    mem_req.data   = 64'b0;
                end

                REQ_P, WAIT_P: begin
                    mem_req      = saved_req;
                    mem_req.addr = paddr;
                end

                default: begin
                    mem_req = '0;
                end
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            cur        <= IDLE;
            kill_state <= KILL_NONE;

            saved_req  <= '0;
            saved_resp <= '0;

            vpn2       <= 9'b0;
            vpn1       <= 9'b0;
            vpn0       <= 9'b0;
            root_addr  <= 64'b0;
            pt_addr    <= 64'b0;
            pte        <= 64'b0;
            paddr      <= 64'b0;
        end
        else if (flush) begin
            cur        <= IDLE;
            saved_req  <= '0;
            saved_resp <= '0;

            kill_state <= cpu_req.valid ? KILL_ADDR : KILL_NONE;

            vpn2       <= 9'b0;
            vpn1       <= 9'b0;
            vpn0       <= 9'b0;
            root_addr  <= 64'b0;
            pt_addr    <= 64'b0;
            pte        <= 64'b0;
            paddr      <= 64'b0;

`ifdef DEBUG
            $display("[MMU_FLUSH] cur=%0d cpu_valid=%b cpu_addr=%h saved_addr=%h",
                     cur, cpu_req.valid, cpu_req.addr, saved_req.addr);
`endif
        end
        else begin
            if (kill_state == KILL_ADDR) begin
                kill_state <= KILL_DATA;
                cur        <= IDLE;

`ifdef DEBUG
                $display("[MMU_KILL_ADDR] cpu_valid=%b cpu_addr=%h",
                         cpu_req.valid, cpu_req.addr);
`endif
            end
            else if (kill_state == KILL_DATA) begin
                kill_state <= KILL_NONE;
                cur        <= IDLE;

`ifdef DEBUG
                $display("[MMU_KILL_DATA] cpu_valid=%b cpu_addr=%h",
                         cpu_req.valid, cpu_req.addr);
`endif
            end
            else begin
                case (cur)

                    IDLE: begin
                        saved_resp <= '0;

                        if (cpu_req.valid) begin
                            saved_req <= cpu_req;

                            vpn2      <= cpu_req.addr[38:30];
                            vpn1      <= cpu_req.addr[29:21];
                            vpn0      <= cpu_req.addr[20:12];
                            root_addr <= {8'b0, satp[43:0], 12'b0};

                            if (translate) begin
                                cur <= REQ_2;
                            end
                            else begin
                                paddr <= cpu_req.addr;
                                cur   <= REQ_P;
                            end

`ifdef DEBUG
                            $display("[MMU_ACCEPT] cpu_addr=%h valid=%b strobe=%h data=%h translate=%b priv=%0d satp=%h",
                                     cpu_req.addr, cpu_req.valid, cpu_req.strobe,
                                     cpu_req.data, translate, privil_mode, satp);
`endif
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

`ifdef DEBUG
                            $display("[MMU_L2_DONE] vaddr=%h pte=%h next_pt=%h",
                                     saved_req.addr, mem_resp.data,
                                     {8'b0, mem_resp.data[53:10], 12'b0});
`endif
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

`ifdef DEBUG
                            $display("[MMU_L1_DONE] vaddr=%h pte=%h next_pt=%h",
                                     saved_req.addr, mem_resp.data,
                                     {8'b0, mem_resp.data[53:10], 12'b0});
`endif
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

`ifdef DEBUG
                            $display("[MMU_L0_DONE] vaddr=%h pte=%h final_paddr=%h",
                                     saved_req.addr, mem_resp.data,
                                     {8'b0, mem_resp.data[53:10], saved_req.addr[11:0]});
`endif
                        end
                    end

                    REQ_P: begin
                        cur <= WAIT_P;
                    end

                    WAIT_P: begin
                        if (mem_resp.data_ok) begin
                            saved_resp <= mem_resp;
                            cur        <= RESP;

`ifdef DEBUG
                            $display("[MMU_MEM_DONE] saved_vaddr=%h paddr=%h resp_data=%h",
                                     saved_req.addr, paddr, mem_resp.data);
`endif
                        end
                    end

                    RESP: begin
`ifdef DEBUG
                        if (cpu_req.valid) begin
                            $display("[MMU_RESP_BLOCK_NEW_REQ] resp_for=%h resp_data=%h blocked_cpu_addr=%h",
                                     saved_req.addr, saved_resp.data, cpu_req.addr);
                        end

                        $display("[MMU_CPU_RESP] saved_addr=%h data_ok=%b data=%h",
                                 saved_req.addr, saved_resp.data_ok, saved_resp.data);
`endif
                        saved_req  <= '0;
                        saved_resp <= '0;
                        cur        <= IDLE;
                    end

                    default: begin
                        cur <= IDLE;
                    end

                endcase
            end
        end
    end

`ifdef DEBUG
    always_ff @(posedge clk) begin
        if (!reset) begin
            if (cpu_req.valid || mem_req.valid || mem_resp.data_ok || cpu_resp.data_ok) begin
                $display("[MMU_STATE] cur=%0d kill=%0d cpu_valid=%b cpu_addr=%h saved_addr=%h paddr=%h mem_valid=%b mem_addr=%h mem_strobe=%h mem_data=%h mem_data_ok=%b mem_data_resp=%h cpu_data_ok=%b cpu_data=%h",
                         cur, kill_state,
                         cpu_req.valid, cpu_req.addr,
                         saved_req.addr, paddr,
                         mem_req.valid, mem_req.addr, mem_req.strobe, mem_req.data,
                         mem_resp.data_ok, mem_resp.data,
                         cpu_resp.data_ok, cpu_resp.data);
            end

            if (cur == IDLE && cpu_resp.data_ok && cpu_req.valid) begin
                $display("[MMU_ERROR_IDLE_RESP_AND_ACCEPT] cpu_addr=%h cpu_resp_data=%h",
                         cpu_req.addr, cpu_resp.data);
            end
        end
    end
`endif

endmodule