`ifdef VERILATOR
`include "include/common.sv"
`include "include/csr.sv"
`include "src/alu_adder.sv"
`include "src/data_valid_unit.sv"
`include "src/alu.sv"
`include "src/alu_md_result_mux.sv"
`include "src/muldiv_unit.sv"
`include "src/trap_router.sv"
`include "src/alures_mux.sv"
`include "src/load_use_hazard.sv"
`include "src/branch_cmp.sv"
`include "src/control_unit.sv"
`include "src/ex_mem_reg.sv"
`include "src/id_ex_reg.sv"
`include "src/if_id_reg.sv"
`include "src/instr_mem.sv"
`include "src/mem_wb_reg.sv"
`include "src/pc_reg.sv"
`include "src/redirect_pc_unit.sv"
`include "src/redirect_valid_unit.sv"
`include "src/reg_file.sv"
`include "src/saf_unit.sv"
`include "src/sign12to64.sv"
`include "src/sign32to64.sv"
`include "src/srcb_mux.sv"
`include "src/srca_mux.sv"
`include "src/data_mem.sv"
`include "src/imm_gen.sv"
`include "src/wbres_mux.sv"
`include "src/csr_file.sv"
`include "src/final_redirect_pc_unit.sv"
`include "src/privilege_unit.sv"
`include "src/dbus_arbiter.sv"
`include "src/mmu.sv"
`include "src/ibus_to_dbus.sv"
`endif

module datapath import common::*;(
    input  logic        clk,
    input  logic        reset,
    input  logic [63:0] PCINIT,

    input logic         trint,
    input logic         swint,
    input logic         exint,

    input  ibus_resp_t  ibus_resp,
    output ibus_req_t   ibus_req,

    input  dbus_resp_t  dbus_resp,
    output dbus_req_t   dbus_req,

    output logic [31:0] test_instr,
    output logic [63:0] test_pc,
    output logic        test_wen,
    output logic [4:0]  test_wdest,
    output logic [63:0] test_wdata,

    output logic        valid,
    output logic [63:0] test_reg_x0,
    output logic [63:0] test_reg_x1,
    output logic [63:0] test_reg_x2,
    output logic [63:0] test_reg_x3,
    output logic [63:0] test_reg_x4,
    output logic [63:0] test_reg_x5,
    output logic [63:0] test_reg_x6,
    output logic [63:0] test_reg_x7,
    output logic [63:0] test_reg_x8,
    output logic [63:0] test_reg_x9,
    output logic [63:0] test_reg_x10,
    output logic [63:0] test_reg_x11,
    output logic [63:0] test_reg_x12,
    output logic [63:0] test_reg_x13,
    output logic [63:0] test_reg_x14,
    output logic [63:0] test_reg_x15,
    output logic [63:0] test_reg_x16,
    output logic [63:0] test_reg_x17,
    output logic [63:0] test_reg_x18,
    output logic [63:0] test_reg_x19,
    output logic [63:0] test_reg_x20,
    output logic [63:0] test_reg_x21,
    output logic [63:0] test_reg_x22,
    output logic [63:0] test_reg_x23,
    output logic [63:0] test_reg_x24,
    output logic [63:0] test_reg_x25,
    output logic [63:0] test_reg_x26,
    output logic [63:0] test_reg_x27,
    output logic [63:0] test_reg_x28,
    output logic [63:0] test_reg_x29,
    output logic [63:0] test_reg_x30,
    output logic [63:0] test_reg_x31,
    output logic mem,
    output logic [63:0] memaddr,

    output logic [63:0] csr_mstatus,
    output logic [63:0] csr_mtvec,
    output logic [63:0] csr_mip,
    output logic [63:0] csr_mie,
    output logic [63:0] csr_mscratch,
    output logic [63:0] csr_mcause,
    output logic [63:0] csr_mtval,
    output logic [63:0] csr_mepc,
    output logic [63:0] csr_mcycle,
    output logic [63:0] csr_mhartid,
    output logic [63:0] csr_satp,

    output logic [63:0] csr_medeleg,
    output logic [63:0] csr_mideleg,
    output logic [63:0] csr_stvec,
    output logic [63:0] csr_sscratch,
    output logic [63:0] csr_sepc,
    output logic [63:0] csr_scause,
    output logic [63:0] csr_stval,
    output logic [63:0] csr_sstatus,
    output logic [63:0] csr_sie,
    output logic [63:0] csr_sip,

    output logic [1:0] privil_mode    

);
//243294

`ifdef VERILA

longint dbg_cyc;
int dbg_print_cnt;

function automatic bit dbg_pc_window();
    dbg_pc_window =
        (pc_f == 64'h0000000080000018) ||
        (pc_f == 64'h000000008000001c) ||
        (pc_f == 64'h0000000080000020) ||
        (pc_f == 64'h0000000080000024) ||
        (pc_f == 64'h0000000080000028) ||
        (pc_f == 64'h000000008000002c) ||
        (pc_f == 64'h0000000080000030) ||
        (valid_d && (
            pc_d == 64'h0000000080000018 ||
            pc_d == 64'h000000008000001c ||
            pc_d == 64'h0000000080000020 ||
            pc_d == 64'h0000000080000024 ||
            pc_d == 64'h0000000080000028 ||
            pc_d == 64'h000000008000002c ||
            pc_d == 64'h0000000080000030
        )) ||
        (valid_e && (
            pc_e == 64'h0000000080000018 ||
            pc_e == 64'h000000008000001c ||
            pc_e == 64'h0000000080000020 ||
            pc_e == 64'h0000000080000024 ||
            pc_e == 64'h0000000080000028 ||
            pc_e == 64'h000000008000002c ||
            pc_e == 64'h0000000080000030
        )) ||
        (valid_m && (
            pc_m == 64'h0000000080000018 ||
            pc_m == 64'h000000008000001c ||
            pc_m == 64'h0000000080000020 ||
            pc_m == 64'h0000000080000024 ||
            pc_m == 64'h0000000080000028 ||
            pc_m == 64'h000000008000002c ||
            pc_m == 64'h0000000080000030
        )) ||
        (valid_w && (
            pc_w == 64'h0000000080000018 ||
            pc_w == 64'h000000008000001c ||
            pc_w == 64'h0000000080000020 ||
            pc_w == 64'h0000000080000024 ||
            pc_w == 64'h0000000080000028 ||
            pc_w == 64'h000000008000002c ||
            pc_w == 64'h0000000080000030
        ));
endfunction

always_ff @(posedge clk) begin
    if (reset) begin
        dbg_cyc <= 0;
        dbg_print_cnt <= 0;
    end else begin
        dbg_cyc <= dbg_cyc + 1;

        if (dbg_pc_window() && dbg_print_cnt < 80) begin
            dbg_print_cnt <= dbg_print_cnt + 1;

            $display(
"[PIPE] cyc=%0d hit=%0d | F pc=%h | D v=%b pc=%h inst=%h | E v=%b pc=%h inst=%h | M v=%b pc=%h inst=%h mr=%b mw=%b addr=%h wdata=%h | W v=%b pc=%h inst=%h rd=%0d wen=%b wdata=%h | stall pc=%b ifid=%b idex=%b exmem=%b memwb=%b mem=%b mdu=%b lu=%b | dreq v=%b addr=%h strb=%h data=%h dok=%b",
                dbg_cyc,
                dbg_print_cnt,
                pc_f,
                valid_d, pc_d, instr_d,
                valid_e, pc_e, instr_e,
                valid_m, pc_m, instr_m, mem_read_m, mem_write_m, aluout_m, rs2_val_m,
                valid_w, pc_w, instr_w, rd_w, regwrite_w, wb_write_data,
                pc_stall, if_id_stall, id_ex_stall, ex_mem_stall, mem_wb_stall,
                mem_stall, mdu_stall, load_use_stall,
                real_dbus_req.valid, real_dbus_req.addr, real_dbus_req.strobe,
                real_dbus_req.data, real_dbus_resp.data_ok
            );
        end
    end
end

`endif

`ifdef DEBUG
    longint dbg_cycle;
    logic dbg_hit_6028;

    always_ff @(posedge clk) begin
        if (reset) begin
            dbg_cycle <= 0;
            dbg_hit_6028 <= 1'b0;
        end
        else begin
            dbg_cycle <= dbg_cycle + 1;

            if (!dbg_hit_6028 && valid_w && pc_w == 64'h000000008000607c) begin
                dbg_hit_6028 <= 1'b1;
                $display("[DBG_HIT_6028] cycle=%0d pc_w=%h instr_w=%h valid_w=%b iaddr_exc_w=%b instr_exc_w=%b daddr_exc_w=%b is_ecall_w=%b is_mret_w=%b trap_valid=%b exception_valid_w=%b trap_cause=%h trap_pc=%h final_redirect_pc=%h privil_mode=%b csr_mstatus=%h csr_mepc=%h csr_mcause=%h csr_mtvec=%h redirect_valid_w=%b redirect_pc_w=%h redirect_valid_m=%b redirect_pc_m=%h redirect_valid_e=%b redirect_pc_e=%h pc_e=%h instr_e=%h valid_e=%b aluout_e=%h rs1_eff_e=%h imm_e=%h", dbg_cycle, pc_w, instr_w, valid_w, iaddr_exc_w, instr_exc_w, daddr_exc_w, is_ecall_w, is_mret_w, trap_valid, exception_valid_w, trap_cause, trap_pc, final_redirect_pc, privil_mode, csr_mstatus, csr_mepc, csr_mcause, csr_mtvec, redirect_valid_w, redirect_pc_w, redirect_valid_m, redirect_pc_m, redirect_valid_e, redirect_pc_e, pc_e, instr_e, valid_e, aluout_e, rs1_eff_e, imm_e);
            end
        end
    end
`endif


`ifdef VERIL
    longint dbg_cycle;

    localparam longint DBG_BEGIN = 1807960;
    localparam longint DBG_END   = 1808000;

    always_ff @(posedge clk) begin
        if (reset) begin
            dbg_cycle <= 0;
        end
        else begin
            dbg_cycle <= dbg_cycle + 1;

            if (dbg_cycle >= DBG_BEGIN && dbg_cycle <= DBG_END) begin
$display("[REDIRECT_ARB] pc_f=%h instr_f=%h instr_valid_f=%b trap_valid=%b mret_valid=%b final_redirect_pc=%h csr_mtvec=%h csr_mepc=%h redirect_valid_e=%b redirect_pc_e=%h redirect_iaddr_exc_e=%b redirect_valid_m=%b redirect_pc_m=%h iaddr_exc_m=%b redirect_valid_w=%b redirect_pc_w=%h iaddr_exc_w=%b if_id_flush=%b id_ex_flush=%b ex_mem_flush=%b mem_wb_flush=%b pc_stall=%b if_id_stall=%b id_ex_stall=%b ex_mem_stall=%b mem_wb_stall=%b",
                pc_f,
                instr_f,
                instr_valid_f,
                trap_valid,
                mret_valid,
                final_redirect_pc,
                csr_mtvec,
                csr_mepc,
                redirect_valid_e,
                redirect_pc_e,
                redirect_iaddr_exc_e,
                redirect_valid_m,
                redirect_pc_m,
                iaddr_exc_m,
                redirect_valid_w,
                redirect_pc_w,
                iaddr_exc_w,
                if_id_flush,
                id_ex_flush,
                ex_mem_flush,
                mem_wb_flush,
                pc_stall,
                if_id_stall,
                id_ex_stall,
                ex_mem_stall,
                mem_wb_stall
            );
            end
        end
    end
`endif



logic fetch_iaddr_exc_e;
logic redirect_iaddr_exc_e;
logic iaddr_exc_e_to_m;

assign fetch_iaddr_exc_e = iaddr_exc_e;

assign redirect_iaddr_exc_e =
    valid_e &&
    redirect_valid_e &&
    (redirect_pc_e[1:0] != 2'b00);

assign iaddr_exc_e_to_m =
    fetch_iaddr_exc_e || redirect_iaddr_exc_e;



// =========================================================
// unified trap / redirect events
// =========================================================
logic        mret_valid;
logic        sret_valid;
logic        exception_valid_w;

logic        interrupt_enable;
logic [63:0] mip_next_for_int;
logic        swint_take;
logic        trint_take;
logic        exint_take;
logic        interrupt_take;

logic        trap_valid;
logic        trap_is_interrupt;
logic [63:0] trap_cause;
logic [63:0] trap_pc;

logic        branch_valid;

// ---------------------------------------------------------
// mret
// ---------------------------------------------------------
assign mret_valid = valid_w && is_mret_w;
assign sret_valid = valid_w && is_sret_w;

// ---------------------------------------------------------
// sync exception
// ---------------------------------------------------------
assign exception_valid_w =
    valid_w && (
        iaddr_exc_w ||
        instr_exc_w ||
        daddr_exc_w ||
        is_ecall_w
    );


assign interrupt_enable =
    (privil_mode != 2'b11) || csr_mstatus[3];

assign mip_next_for_int =
    csr_mip |
    (swint ? 64'h0000_0000_0000_0008 : 64'b0) |
    (trint ? 64'h0000_0000_0000_0080 : 64'b0) |
    (exint ? 64'h0000_0000_0000_0800 : 64'b0);

assign swint_take =
    swint &&
    interrupt_enable &&
    mip_next_for_int[3] &&
    csr_mie[3];

assign trint_take =
    trint &&
    interrupt_enable &&
    mip_next_for_int[7] &&
    csr_mie[7];

assign exint_take =
    exint &&
    interrupt_enable &&
    mip_next_for_int[11] &&
    csr_mie[11];

assign interrupt_take =
    !exception_valid_w &&
    !mret_valid &&
    !sret_valid &&
    (exint_take || trint_take || swint_take);

// ---------------------------------------------------------
// final trap
// ---------------------------------------------------------
// trap_valid 本周期是否trap entry
assign trap_valid        = exception_valid_w || interrupt_take;
assign trap_is_interrupt = interrupt_take;

// 异常 mepc = 异常指令 pc。
// 中断是异步 trap，这里用当前 fetch pc 作为恢复点。
//assign trap_pc =
//    exception_valid_w ? pc_w : pc_f;

logic [63:0] last_valid_pc;

always_ff @(posedge clk) begin
    if (reset) begin
        last_valid_pc <= PCINIT;
    end else begin
        if (valid_w) begin
            last_valid_pc <= pc_w + 64'd4;
        end else if (valid_m) begin
            last_valid_pc <= pc_m;
        end else if (valid_e) begin
            last_valid_pc <= pc_e;
        end else if (valid_d) begin
            last_valid_pc <= pc_d;
        end else if (instr_valid_f) begin
            last_valid_pc <= pc_f;
        end
    end
end

assign trap_pc =
    exception_valid_w ? pc_w : last_valid_pc;

// ---------------------------------------------------------
// branch
// ---------------------------------------------------------
assign branch_valid = redirect_valid_e;

// ---------------------------------------------------------
// trap cause
// 优先级：
//   iaddr_exc > illegal_instr > daddr_exc > ecall > external > timer > software
// ---------------------------------------------------------
always_comb begin
    trap_cause = 64'b0;

    if (iaddr_exc_w) begin
        trap_cause = 64'd0;      // instruction address misaligned
    end
    else if (instr_exc_w) begin
        trap_cause = 64'd2;      // illegal instruction
    end
    else if (daddr_exc_w) begin
        if (instr_w[6:0] == 7'b0100011)
            trap_cause = 64'd6;  // store address misaligned
        else
            trap_cause = 64'd4;  // load address misaligned
    end
    else if (valid_w && is_ecall_w) begin
        if (privil_mode == 2'b00)
            trap_cause = 64'd8;  // ecall from U
        else
            trap_cause = 64'd11; // ecall from M
    end
    else if (exint_take) begin
        trap_cause = 64'd11;     // machine external interrupt
    end
    else if (trint_take) begin
        trap_cause = 64'd7;      // machine timer interrupt
    end
    else if (swint_take) begin
        trap_cause = 64'd3;      // machine software interrupt
    end
end

    logic [1:0] trap_target_priv;

    trap_router u_trap_router (
        .trap_valid       (trap_valid),
        .trap_is_interrupt(trap_is_interrupt),
        .trap_cause       (trap_cause),
        .current_priv     (privil_mode),
        .csr_medeleg      (csr_medeleg),
        .csr_mideleg      (csr_mideleg),
        .trap_target_priv (trap_target_priv)
    );

    // exception & interruption
    logic iaddr_exc_f;
    logic iaddr_exc_d;
    logic iaddr_exc_e;
    logic iaddr_exc_m;
    logic iaddr_exc_w;


    logic daddr_exc_m;
    logic daddr_exc_w;


    logic instr_exc_d;
    logic instr_exc_e;
    logic instr_exc_m;
    logic instr_exc_w;

    data_valid_unit DVU(
        .address     (aluout_m),
        .daddr_exc_m (daddr_exc_m),
        .mem_write_m (mem_write_m),
        .mem_read_m  (mem_read_m),
        .mem_digit_m (mem_digit_m)
    );




// MMU & bus
logic bus_cancel;

// 事务级取消：只有 W 阶段有效提交的 ecall/mret 才能取消总线事务
assign bus_cancel = trap_valid || mret_valid;

    ibus_resp_t  real_ibus_resp;
    ibus_req_t   real_ibus_req;

    dbus_resp_t  real_dbus_resp;
    dbus_req_t   real_dbus_req;

    dbus_resp_t  virtual_dbus_resp;
    dbus_req_t   virtual_dbus_req;

    dbus_resp_t  instr_dbus_resp;
    dbus_req_t   instr_dbus_req;


    ibus_to_dbus itd(
    .clk    (clk),
    .reset  (reset),
    .cancel (bus_cancel),
    .iresp  (real_ibus_resp),
    .ireq   (real_ibus_req),
    .dresp  (instr_dbus_resp),
    .dreq   (instr_dbus_req)
);

dbus_arbiter ab(
    .clk        (clk),
    .reset      (reset),
    .cancel     (bus_cancel),

    .reqs       ({instr_dbus_req, real_dbus_req}),
    .resps      ({instr_dbus_resp, real_dbus_resp}),

    .final_req  (virtual_dbus_req),
    .final_resp (virtual_dbus_resp)
);
mmu mmu(
    .clk         (clk),
    .reset       (reset),
    .flush       (bus_cancel),

    .cpu_req     (virtual_dbus_req),
    .cpu_resp    (virtual_dbus_resp),

    .mem_req     (dbus_req),
    .mem_resp    (dbus_resp),

    .satp        (csr_satp),
    .privil_mode (privil_mode)
);


    assign ibus_req='0;



    // =========================================================
    // stall / flush / redirect
    // =========================================================
    logic pc_stall;
    logic if_id_stall;
    logic id_ex_stall;
    logic ex_mem_stall;
    logic mem_wb_stall;
    logic mem_stall;

    logic if_id_flush;
    logic id_ex_flush;
    logic ex_mem_flush;
    logic mem_wb_flush;

    logic        redirect_valid_e;
    logic        redirect_valid_m;
    logic        redirect_valid_w;

    logic [63:0] redirect_pc_e;
    logic [63:0] redirect_pc_m;
    logic [63:0] redirect_pc_w;

saf_unit st(
    .mem_stall             (mem_stall),
    .load_use_stall        (load_use_stall),

    .branch_redirect_valid (branch_valid),
    .trap_valid            (trap_valid),
    .mret_valid            (mret_valid),

    .pc_stall              (pc_stall),
    .if_id_stall           (if_id_stall),
    .id_ex_stall           (id_ex_stall),
    .ex_mem_stall          (ex_mem_stall),
    .mem_wb_stall          (mem_wb_stall),

    .if_id_flush           (if_id_flush),
    .id_ex_flush           (id_ex_flush),
    .ex_mem_flush          (ex_mem_flush),
    .mem_wb_flush          (mem_wb_flush),

    .mdu_stall             (mdu_stall),
    .sret_valid            (sret_valid)
);

    // =========================================================
    // csr
    // =========================================================

    
    logic [63:0] csr_value_d;
    logic [63:0] csr_value_e;
    logic [63:0] csr_value_m;
    logic [63:0] csr_value_w;

    logic [11:0] csr_num_d;
    logic [11:0] csr_num_e;
    logic [11:0] csr_num_m;
    logic [11:0] csr_num_w;

    logic [63:0] csr_operand_d;
    logic [63:0] csr_operand_e;
    logic [63:0] csr_operand_m;
    logic [63:0] csr_operand_w;

    logic csrwrite_d;
    logic csrwrite_e;
    logic csrwrite_m;
    logic csrwrite_w;

// CSR 写入 operand
// 注意：这里不是最终写入 CSR 的值。
// CSRRW/CSRRS/CSRRC 传 rs1_val。
// CSRRWI/CSRRSI/CSRRCI 传 zimm。
// 最终 OR / AND / CLEAR 仍然由 csr_file 根据 instr_m[14:12] 完成。
always_comb begin
    unique case (instr_d[14:12])
        3'b001, 3'b010, 3'b011: begin
            csr_operand_d = rs1_val_d;
        end

        3'b101, 3'b110, 3'b111: begin
            csr_operand_d = {59'b0, instr_d[19:15]};
        end

        default: begin
            csr_operand_d = 64'b0;
        end
    endcase
end

csr_file cf(
    .clk           (clk),
    .reset         (reset),

    .instr_d       (instr_d),
    .instr_w       (instr_w),

    .new_csr_num   (csr_num_w),
    .new_csr_value (csr_operand_w),
    .csrwrite      (csrwrite_w & valid_w),

    .trap_valid        (trap_valid),
    .trap_is_interrupt (trap_is_interrupt),
    .trap_cause        (trap_cause),
    .trap_pc           (trap_pc),
    .trap_priv         (privil_mode),

    .mret_valid    (mret_valid),

    .swint         (swint),
    .trint         (trint),
    .exint         (exint),

    .csr_value     (csr_value_d),
    .csr_num       (csr_num_d),

    .csr_mtvec     (csr_mtvec),
    .csr_mip       (csr_mip),
    .csr_mie       (csr_mie),
    .csr_mscratch  (csr_mscratch),
    .csr_mcause    (csr_mcause),
    .csr_mtval     (csr_mtval),
    .csr_mepc      (csr_mepc),
    .csr_mcycle    (csr_mcycle),
    .csr_mhartid   (csr_mhartid),
    .csr_satp      (csr_satp),
    .csr_mstatus   (csr_mstatus),
    .csr_medeleg    (csr_medeleg),
    .csr_mideleg    (csr_mideleg),
    .csr_stvec      (csr_stvec),
    .csr_sscratch   (csr_sscratch),
    .csr_sepc       (csr_sepc),
    .csr_scause     (csr_scause),
    .csr_stval      (csr_stval),
    .csr_sstatus    (csr_sstatus),
    .csr_sie        (csr_sie),
    .csr_sip        (csr_sip),

    .trap_target_priv    (trap_target_priv),
    .sret_valid     (sret_valid)
);


 
    // =========================================================
    // PRIVILEGE_UNIT
    // =========================================================
    logic is_ecall_f;
    logic is_ecall_d;
    logic is_ecall_e;
    logic is_ecall_m;
    logic is_ecall_w;

    logic is_mret_f;
    logic is_mret_d;
    logic is_mret_e;
    logic is_mret_m;
    logic is_mret_w;

    logic is_sret_f;
    logic is_sret_d;
    logic is_sret_e;
    logic is_sret_m;
    logic is_sret_w;



privilege_unit pu(
    .clk(clk),
    .rst(reset),

    .trap_valid(trap_valid),
    .mret_valid(mret_valid),

    .mpp(csr_mstatus[12:11]),
    .privil_mode(privil_mode),

    .spp    (csr_mstatus[8]),
    .sret_valid     (sret_valid),
    .trap_target_priv   (trap_target_priv)
);


    // =========================================================
    // 1. IF
    // =========================================================

    logic        fetch_consume;
    logic instr_valid_f;

    logic [31:0] instr_f;
    logic [31:0] instr_d;
    logic [31:0] instr_e;
    logic [31:0] instr_m;
    logic [31:0] instr_w;

    logic [63:0] pc_f;
    logic [63:0] pc_d;
    logic [63:0] pc_e;
    logic [63:0] pc_m;
    logic [63:0] pc_w;

    logic valid_d;
    logic valid_e;
    logic valid_m;
    logic valid_w;

    assign fetch_consume = instr_valid_f & ~if_id_stall;

logic final_redirect_valid;

assign final_redirect_valid =
    branch_valid ||
    trap_valid ||
    mret_valid;


    instr_mem if3(
        .clk            (clk),
        .reset          (reset),
        .consume        (fetch_consume),

        .pc_stall       (pc_stall),
        .ibus_resp      (real_ibus_resp),
        .pcinit         (PCINIT),
        .redirect_pc    (final_redirect_pc),
        .branch_redirect_valid (final_redirect_valid),
        
        .is_ecall       (1'b0),
        .is_mret        (1'b0),

        .iaddr_exc      (iaddr_exc_f),
        .instr          (instr_f),
        .ibus_req       (real_ibus_req),
        .pc             (pc_f),
        .instr_valid    (instr_valid_f)
    );

    // =========================================================
    // IF/ID
    // =========================================================
    if_id_reg if_id(
        .instr_f     (instr_f),
        .clk         (clk),
        .fetch_ok    (instr_valid_f),
        .pc_f        (pc_f),
        .reset       (reset),
        .if_id_stall (if_id_stall),
        .flush       (if_id_flush),
        .instr_d     (instr_d),
        .valid_d     (valid_d),
        .pc_d        (pc_d),
        .iaddr_exc_f (iaddr_exc_f),
        .iaddr_exc_d (iaddr_exc_d)
    );

    // =========================================================
    // 2. ID
    // =========================================================
    logic [2:0]  funct3;
    logic [6:0]  funct7;
    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [4:0]  rd;
    logic [6:0]  opcode;
    logic [11:0] immediate;

    logic [63:0] imm_d;
    logic [63:0] rs1_val_d;
    logic [63:0] rs2_val_d;

    logic        alusign_d;
    logic [3:0]  aluctrl_d;
    logic [1:0]  alusrca_d;
    logic [1:0]  alusrcb_d;
    logic        regwrite_d;
    logic        mem_write_d;
    logic        mem_read_d;
    logic        mem_sign_d;
    logic [1:0]  wb_result_d;
    logic [1:0]  mem_digit_d;

    logic        cmpsrc_d;
    logic [1:0]  is_baj_d;
    logic [2:0]  branch_type_d;


    assign opcode = instr_d[6:0];
    assign rd     = instr_d[11:7];
    assign funct3 = instr_d[14:12];
    assign funct7 = instr_d[31:25];
    assign rs1    = instr_d[19:15];
    assign rs2    = instr_d[24:20];
    assign immediate = instr_d[31:20];

    logic [4:0] rs1_d, rs2_d;//就是rs1和rs2，接给load use hazard
    logic load_use_stall;

    assign rs1_d = instr_d[19:15];
    assign rs2_d = instr_d[24:20];

    load_use_hazard HZD1(
        .mem_read_e      (mem_read_e),
        .rd_e            (rd_e),
        .rs1_d           (rs1_d),
        .rs2_d           (rs2_d),
        .load_use_stall  (load_use_stall)
    );

    control_unit ID1(
        .funct7        (funct7),
        .funct3        (funct3),
        .opcode        (opcode),
        .bit30         (instr_d[30]),
        .immediate      (immediate),

        .alusign_d     (alusign_d),
        .aluctrl_d     (aluctrl_d),
        .alusrcb_d     (alusrcb_d),
        .regwrite_d    (regwrite_d),
        .mem_write_d   (mem_write_d),
        .mem_read_d    (mem_read_d),
        .mem_sign_d    (mem_sign_d),
        .wb_result_d   (wb_result_d),
        .mem_digit_d   (mem_digit_d),
        .alusrca_d     (alusrca_d),
        .csrwrite_d    (csrwrite_d),
        .is_ecall_d     (is_ecall_d),
        .is_mret_d      (is_mret_d),
        .is_sret_d      (is_sret_d),

        .cmpsrc_d      (cmpsrc_d),
        .is_baj_d      (is_baj_d),
        .branch_type_d (branch_type_d)

    );

    logic [63:0] wb_write_data;
    logic [4:0]  rd_w;
    logic        regwrite_w;

    reg_file ID2(
        .rs1          (rs1),
        .rs2          (rs2),
        .writedata    (wb_write_data),
        .rd           (rd_w),
        .regwrite     (regwrite_w & valid_w),
        .clk          (clk),
        .reset        (reset),

        .rs1_val_d    (rs1_val_d),
        .rs2_val_d    (rs2_val_d),

        .test_reg_x0  (test_reg_x0),
        .test_reg_x1  (test_reg_x1),
        .test_reg_x2  (test_reg_x2),
        .test_reg_x3  (test_reg_x3),
        .test_reg_x4  (test_reg_x4),
        .test_reg_x5  (test_reg_x5),
        .test_reg_x6  (test_reg_x6),
        .test_reg_x7  (test_reg_x7),
        .test_reg_x8  (test_reg_x8),
        .test_reg_x9  (test_reg_x9),
        .test_reg_x10 (test_reg_x10),
        .test_reg_x11 (test_reg_x11),
        .test_reg_x12 (test_reg_x12),
        .test_reg_x13 (test_reg_x13),
        .test_reg_x14 (test_reg_x14),
        .test_reg_x15 (test_reg_x15),
        .test_reg_x16 (test_reg_x16),
        .test_reg_x17 (test_reg_x17),
        .test_reg_x18 (test_reg_x18),
        .test_reg_x19 (test_reg_x19),
        .test_reg_x20 (test_reg_x20),
        .test_reg_x21 (test_reg_x21),
        .test_reg_x22 (test_reg_x22),
        .test_reg_x23 (test_reg_x23),
        .test_reg_x24 (test_reg_x24),
        .test_reg_x25 (test_reg_x25),
        .test_reg_x26 (test_reg_x26),
        .test_reg_x27 (test_reg_x27),
        .test_reg_x28 (test_reg_x28),
        .test_reg_x29 (test_reg_x29),
        .test_reg_x30 (test_reg_x30),
        .test_reg_x31 (test_reg_x31)
    );

    imm_gen ID3(
        .instr_d (instr_d),
        .imm_d   (imm_d)
    );

    // =========================================================
    // ID/EX
    // =========================================================
    logic [63:0] rs1_val_e;
    logic [63:0] rs2_val_e;
    logic [63:0] imm_e;
    logic [4:0]  rd_e;

    logic        alusign_e;
    logic [3:0]  aluctrl_e;
    logic [1:0]  alusrca_e;
    logic [1:0]   alusrcb_e;
    logic        mem_write_e;
    logic        mem_read_e;
    logic [1:0]   wbresult_e;
    logic [1:0]  mem_digit_e;
    logic        mem_sign_e;
    logic        regwrite_e;

    logic [2:0]  branch_type_e;
    logic        cmpsrc_e;
    logic [1:0]  is_baj_e;

    id_ex_reg id_ex(
        .csr_operand_d(csr_operand_d),
        .csr_operand_e(csr_operand_e),
        .clk           (clk),
        .rs1_val_d     (rs1_val_d),
        .rs2_val_d     (rs2_val_d),
        .imm_d         (imm_d),
        .rd_d          (rd),
        .alusign_d     (alusign_d),
        .aluctrl_d     (aluctrl_d),
        .alusrcb_d     (alusrcb_d),
        .alusrca_d     (alusrca_d),
        .mem_write_d   (mem_write_d),
        .mem_read_d    (mem_read_d),
        .wbresult_d    (wb_result_d),
        .mem_digit_d   (mem_digit_d),
        .mem_sign_d    (mem_sign_d),
        .regwrite_d    (regwrite_d),
        .pc_d          (pc_d),
        .instr_d       (instr_d),
        .valid_d       (valid_d),
        .reset         (reset),
        .flush         (id_ex_flush),
        .id_ex_stall   (id_ex_stall),
        .branch_type_d (branch_type_d),
        .cmpsrc_d      (cmpsrc_d),
        .is_baj_d      (is_baj_d),
        .csrwrite_d  (csrwrite_d),
        .csr_num_d  (csr_num_d),
        .csr_value_d(csr_value_d),

        .is_ecall_d (is_ecall_d),
        .is_mret_d  (is_mret_d),
        .is_ecall_e (is_ecall_e),
        .is_mret_e  (is_mret_e),

        .is_sret_d  (is_sret_d),
        .is_sret_e  (is_sret_e),

        .csr_num_e  (csr_num_e),
        .csr_value_e(csr_value_e),

        .csrwrite_e  (csrwrite_e),
        .wbresult_e    (wbresult_e),
        .valid_e       (valid_e),
        .instr_e       (instr_e),
        .pc_e          (pc_e),
        .rs1_val_e     (rs1_val_e),
        .rs2_val_e     (rs2_val_e),
        .imm_e         (imm_e),
        .rd_e          (rd_e),
        .alusign_e     (alusign_e),
        .aluctrl_e     (aluctrl_e),
        .branch_type_e (branch_type_e),
        .cmpsrc_e      (cmpsrc_e),
        .is_baj_e      (is_baj_e),
        .alusrca_e     (alusrca_e),
        .alusrcb_e     (alusrcb_e),
        .mem_write_e   (mem_write_e),
        .mem_read_e    (mem_read_e),
        .mem_sign_e    (mem_sign_e),
        .mem_digit_e   (mem_digit_e),
        .regwrite_e    (regwrite_e),

        .iaddr_exc_d   (iaddr_exc_d),
        .iaddr_exc_e   (iaddr_exc_e)
    );

    // =========================================================
    // 3. EX
    // =========================================================
    logic [63:0] srca_e;
    logic [63:0] srcb_e;
    logic [63:0] alu_result_e;
    logic [63:0] long_alu_result_e;
    logic [63:0] aluout_e;

    logic [63:0] rs1_eff_e;
    logic [63:0] rs2_eff_e;

    logic [63:0] cmp_b_e;
    logic        cmp_res;

always_comb begin
    rs1_eff_e = rs1_val_e;
    rs2_eff_e = rs2_val_e;

    // rs1
    if (valid_m && regwrite_m && (rd_m != 5'd0) && (rd_m == instr_e[19:15])) begin
        if (!mem_read_m) begin
            rs1_eff_e = aluout_m;
        end
        else if (dbus_resp.data_ok) begin
            rs1_eff_e = mem_read_data_m;
        end
    end
    else if (valid_w && regwrite_w && (rd_w != 5'd0) &&
             (rd_w == instr_e[19:15])) begin
        rs1_eff_e = wb_write_data;
    end

    // rs2
    if (valid_m && regwrite_m && (rd_m != 5'd0) && (rd_m == instr_e[24:20])) begin
        if (!mem_read_m) begin
            rs2_eff_e = aluout_m;
        end
        else if (dbus_resp.data_ok) begin
            rs2_eff_e = mem_read_data_m;
        end
    end
    else if (valid_w && regwrite_w && (rd_w != 5'd0) &&
             (rd_w == instr_e[24:20])) begin
        rs2_eff_e = wb_write_data;
    end
end

    srca_mux EX5(
        .rs1_val_e (rs1_eff_e),
        .alusrca_e (alusrca_e),
        .pc_e      (pc_e),
        .srca_e    (srca_e)
    );

    srcb_mux EX1(
        .imm_e      (imm_e),
        .rs2_val_e  (rs2_eff_e),
        .alusrcb_e  (alusrcb_e),
        .srcb_e     (srcb_e)
    );
    logic        is_mdu_e;
    logic        mdu_req_valid;
    logic        mdu_req_ready;
    logic        mdu_resp_valid;
    logic [63:0] mdu_resp_result;

    logic        ex_done;
    logic [63:0] alu_result_final_e;
    logic        mdu_stall;

    alu EX2(
        .srca_e       (srca_e),
        .srcb_e       (srcb_e),
        .aluctrl_e    (aluctrl_e),
        .alusign_e    (alusign_e),
        .alu_result_e (alu_result_e)
    );
    assign is_mdu_e =
        valid_e &&
        (
            aluctrl_e == 4'd10 ||
            aluctrl_e == 4'd11 ||
            aluctrl_e == 4'd12 ||
            aluctrl_e == 4'd13 ||
            aluctrl_e == 4'd14
        );

    assign mdu_req_valid = is_mdu_e && mdu_req_ready;

    assign ex_done = !is_mdu_e || mdu_resp_valid;

    assign mdu_stall = valid_e && !ex_done;

muldiv_unit mu(
    .clk         (clk),
    .reset       (reset),

    .req_valid   (mdu_req_valid),
    .req_srca    (srca_e),
    .req_srcb    (srcb_e),
    .req_op      (aluctrl_e),
    .req_word    (alusign_e),

    .req_ready   (mdu_req_ready),

    .resp_valid  (mdu_resp_valid),
    .resp_result (mdu_resp_result)
);

assign alu_result_final_e =
    is_mdu_e ? mdu_resp_result : final_alures;

assign aluout_e = alu_result_final_e;

    sign32to64 EX3(
        .short_imm (alu_result_e),
        .long_imm  (long_alu_result_e)
    );

    logic [63:0] final_alures;
    alures_mux EX4(
        .alusign_e          (alusign_e),
        .alu_result_e       (alu_result_e),
        .long_alu_result_e  (long_alu_result_e),
        .final_alu_result_e (final_alures)
    );

    assign cmp_b_e = cmpsrc_e ? imm_e : rs2_eff_e;

    branch_cmp EXCMP(
        .a             (rs1_eff_e),
        .b             (cmp_b_e),
        .branch_type_e (branch_type_e),
        .cmp_res       (cmp_res)
    );

    redirect_valid_unit EXRV(
        .cmp_res        (cmp_res),
        .is_baj_e       (is_baj_e),
        .redirect_valid (redirect_valid_e)
    );

    redirect_pc_unit EXRP(
        .alu_res     (aluout_e),
        .is_baj_e    (is_baj_e),
        .redirect_pc (redirect_pc_e)
    );

    logic [63:0] final_redirect_pc;

final_redirect_pc_unit frp(
    .branch_redirect_pc    (redirect_pc_e),
    .branch_redirect_valid (branch_valid),

    .csr_mepc              (csr_mepc),
    .csr_mtvec             (csr_mtvec),

    .csr_sepc              (csr_sepc),
    .csr_stvec             (csr_stvec),

    .trap_valid            (trap_valid),
    .mret_valid            (mret_valid),
    .sret_valid            (sret_valid),
    .trap_target_priv      (trap_target_priv),

    .final_redirect_pc     (final_redirect_pc)
);

    // =========================================================
    // EX/MEM
    // =========================================================
    logic [1:0]  wb_result_m;
    logic        mem_write_m;
    logic        mem_read_m;
    logic        mem_sign_m;
    logic [1:0]  mem_digit_m;
    logic [63:0] aluout_m;
    logic [4:0]  rd_m;
    logic        regwrite_m;
    logic [63:0] rs2_val_m;
    logic [1:0]  is_baj_m;

    ex_mem_reg ex_mem(
        .flush          (ex_mem_flush),
        .csr_operand_e(csr_operand_e),
        .csr_operand_m(csr_operand_m),
        .mem_write_e        (mem_write_e),
        .mem_read_e         (mem_read_e),
        .mem_sign_e         (mem_sign_e),
        .wb_result_e        (wbresult_e),
        .mem_digit_e        (mem_digit_e),
        .final_alu_result_e (aluout_e),
        .rd_e               (rd_e),
        .regwrite_e         (regwrite_e),
        .clk                (clk),
        .reset              (reset),
        .pc_e               (pc_e),
        .instr_e            (instr_e),
        .valid_e            (valid_e),
        .rs2_val_e          (rs2_eff_e),
        .ex_mem_stall       (ex_mem_stall),
        .is_baj_e           (is_baj_e),
        .csrwrite_e  (csrwrite_e),
        .csr_num_e  (csr_num_e),
        .csr_value_e(csr_value_e),
        .csr_num_m  (csr_num_m),
        .csr_value_m(csr_value_m),

        .is_ecall_m (is_ecall_m),
        .is_mret_m  (is_mret_m),
        .is_ecall_e (is_ecall_e),
        .is_mret_e  (is_mret_e),

        .is_sret_e  (is_sret_e),
        .is_sret_m  (is_sret_m),

        .iaddr_exc_m   (iaddr_exc_m),
        .iaddr_exc_e    (iaddr_exc_e_to_m),
        .redirect_pc_m (redirect_pc_m),
        .redirect_pc_e (redirect_pc_e),
        .redirect_valid_m (redirect_valid_m),
        .redirect_valid_e (redirect_valid_e),

        .csrwrite_m  (csrwrite_m),
        .wb_result_m        (wb_result_m),
        .valid_m            (valid_m),
        .pc_m               (pc_m),
        .instr_m            (instr_m),
        .mem_write_m        (mem_write_m),
        .mem_read_m         (mem_read_m),
        .mem_sign_m         (mem_sign_m),
        .mem_digit_m        (mem_digit_m),
        .final_alu_result_m (aluout_m),
        .rd_m               (rd_m),
        .regwrite_m         (regwrite_m),
        .rs2_val_m          (rs2_val_m),
        .is_baj_m           (is_baj_m)
    );

    // =========================================================
    // 4. MEM
    // =========================================================
    logic [63:0] mem_read_data_m;
    logic [63:0] mem_write_data_w;

    data_mem MEM1(
        .clk            (clk),
        .rst            (reset),
        .valid_m        (valid_m),
        .address        (aluout_m),
        .mem_write_data (rs2_val_m),
        .mem_write_m    (mem_write_m),
        .mem_read_m     (mem_read_m),
        .mem_digit_m    (mem_digit_m),
        .mem_sign_m     (mem_sign_m),

        .dresp          (real_dbus_resp),
        .dreq           (real_dbus_req),

        .mem_read_data  (mem_read_data_m),
        .mem_stall      (mem_stall),

        .daddr_exc_m    (daddr_exc_m)
    );
    // =========================================================
    // MEM/WB
    // =========================================================
    logic [1:0]  wb_result_w;
    logic [63:0] aluout_w;
    logic [1:0]  is_baj_w;

    mem_wb_reg mem_wb(
        .flush            (1'b0),//暂时写成0，防止把自己刷掉。
        .aluout_m         (aluout_m),
        .mem_write_data_m (mem_read_data_m),
        .rd_m             (rd_m),
        .wb_result_m      (wb_result_m),
        .regwrite_m       (regwrite_m),
        .clk              (clk),
        .reset            (reset),
        .pc_m             (pc_m),
        .instr_m          (instr_m),
        .valid_m          (valid_m),
        .mem_wb_stall     (mem_wb_stall),
        .is_baj_m         (is_baj_m),
        .csrwrite_m  (csrwrite_m),
        .csrwrite_w  (csrwrite_w),

        .is_ecall_m (is_ecall_m),
        .is_mret_m  (is_mret_m),
        .is_ecall_w (is_ecall_w),
        .is_mret_w (is_mret_w),

        .is_sret_m  (is_sret_m),
        .is_sret_w (is_sret_w),

        .csr_num_m  (csr_num_m),
        .csr_value_m (csr_value_m),
        .csr_num_w  (csr_num_w),
        .csr_value_w(csr_value_w),
        .is_baj_w         (is_baj_w),
        .mem_write_data_w (mem_write_data_w),
        .wb_result_w      (wb_result_w),
        .pc_w             (pc_w),
        .instr_w          (instr_w),
        .aluout_w         (aluout_w),
        .rd_w             (rd_w),
        .regwrite_w       (regwrite_w),
        .valid_w          (valid_w),

        .iaddr_exc_m   (iaddr_exc_m),
        .iaddr_exc_w   (iaddr_exc_w),
        .redirect_pc_m (redirect_pc_m),
        .redirect_pc_w (redirect_pc_w),
        .redirect_valid_m (redirect_valid_m),
        .redirect_valid_w (redirect_valid_w),
        .daddr_exc_w    (daddr_exc_w),
        .daddr_exc_m    (daddr_exc_m),

        .csr_operand_m  (csr_operand_m),
        .csr_operand_w  (csr_operand_w)
    );

    // =========================================================
    // 5. WB
    // =========================================================
    wbres_mux WB1(
        .wb_result_w      (wb_result_w),
        .is_baj_w         (is_baj_w),
        .aluout_w         (aluout_w),
        .mem_write_data_w (mem_write_data_w),
        .pc_w             (pc_w),
        .wb_write_data    (wb_write_data),
        .csr_value_w      (csr_value_w)
    );

    // =========================================================
    // commit for test
    // =========================================================
    
    logic        mem_inst_w;
    logic        commit_mem_valid;
    logic [63:0] commit_mem_addr;

    assign mem_inst_w =
    (instr_w[6:0] == 7'b0000011) ||   // LOAD
    (instr_w[6:0] == 7'b0100011);     // STORE
    
    logic        commit_valid;
    logic [63:0] commit_pc;
    logic [31:0] commit_instr;
    logic        commit_wen;
    logic [4:0]  commit_wdest;
    logic [63:0] commit_wdata;

        

always_ff @(posedge clk) begin
    if (reset) begin
        commit_valid <= 1'b0;
        commit_pc    <= 64'b0;
        commit_instr <= 32'b0;
        commit_wen   <= 1'b0;
        commit_wdest <= 5'b0;
        commit_wdata <= 64'b0;
        commit_mem_valid <= 1'b0;
        commit_mem_addr  <= 64'b0;
    end else begin
        commit_valid <= valid_w;

        commit_pc    <= pc_w;
        commit_instr <= instr_w;
        commit_wen   <= regwrite_w & valid_w;
        commit_wdest <= rd_w;
        commit_wdata <= wb_write_data;
        commit_mem_valid <= mem_inst_w & valid_w;
        commit_mem_addr  <= aluout_w;
    end
end

    assign valid = commit_valid;
    assign mem = commit_mem_valid & commit_valid;
    assign memaddr  = commit_mem_addr;

    assign test_pc    = commit_pc;
    assign test_instr = commit_instr;
    assign test_wen   = commit_wen & commit_valid;
    assign test_wdest = commit_wdest;
    assign test_wdata = commit_wdata;

endmodule
