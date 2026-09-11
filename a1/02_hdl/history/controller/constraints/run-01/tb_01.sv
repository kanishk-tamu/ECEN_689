`timescale 1ns/1ps

module controller_tb;

  logic [31:0] InstrD;
  logic        RegWriteD;
  logic [2:0]  ImmSrcD;
  logic        ALUSrcAD;
  logic        ALUSrcBD;
  logic [1:0]  MemRWD;
  logic [2:0]  ResultSrcD;
  logic        BranchD;
  logic        JumpD;
  logic        ALUResultSrcD;
  logic [2:0]  ALUSelectD;
  logic        SubArithD;
  logic        IllegalInstrD;

  integer passed;
  integer failed;
  integer total;
  integer fail_prints;

  controller dut (
      .InstrD(InstrD),
      .RegWriteD(RegWriteD),
      .ImmSrcD(ImmSrcD),
      .ALUSrcAD(ALUSrcAD),
      .ALUSrcBD(ALUSrcBD),
      .MemRWD(MemRWD),
      .ResultSrcD(ResultSrcD),
      .BranchD(BranchD),
      .JumpD(JumpD),
      .ALUResultSrcD(ALUResultSrcD),
      .ALUSelectD(ALUSelectD),
      .SubArithD(SubArithD),
      .IllegalInstrD(IllegalInstrD)
  );

  initial begin
    #100000;
    $display("FAIL");
    $finish;
  end

  function automatic [31:0] enc_r(
      input [6:0] funct7,
      input [4:0] rs2,
      input [4:0] rs1,
      input [2:0] funct3,
      input [4:0] rd,
      input [6:0] opcode
  );
    enc_r = {funct7, rs2, rs1, funct3, rd, opcode};
  endfunction

  function automatic [31:0] enc_i(
      input [11:0] imm12,
      input [4:0]  rs1,
      input [2:0]  funct3,
      input [4:0]  rd,
      input [6:0]  opcode
  );
    enc_i = {imm12, rs1, funct3, rd, opcode};
  endfunction

  function automatic [31:0] enc_s(
      input [11:0] imm12,
      input [4:0]  rs2,
      input [4:0]  rs1,
      input [2:0]  funct3,
      input [6:0]  opcode
  );
    enc_s = {imm12[11:5], rs2, rs1, funct3, imm12[4:0], opcode};
  endfunction

  function automatic [31:0] enc_b(
      input [12:0] imm13,
      input [4:0]  rs2,
      input [4:0]  rs1,
      input [2:0]  funct3,
      input [6:0]  opcode
  );
    enc_b = {imm13[12], imm13[10:5], rs2, rs1, funct3, imm13[4:1], imm13[11], opcode};
  endfunction

  function automatic [31:0] enc_u(
      input [19:0] imm20,
      input [4:0]  rd,
      input [6:0]  opcode
  );
    enc_u = {imm20, rd, opcode};
  endfunction

  function automatic [31:0] enc_j(
      input [20:0] imm21,
      input [4:0]  rd,
      input [6:0]  opcode
  );
    enc_j = {imm21[20], imm21[10:1], imm21[11], imm21[19:12], rd, opcode};
  endfunction

  task automatic cmp1(
      input [255:0] label,
      input [31:0] instr,
      input actual,
      input expected
  );
    begin
      total = total + 1;
      if (actual === expected) begin
        passed = passed + 1;
      end else begin
        failed = failed + 1;
        if (fail_prints < 8) begin
          $display("FAIL %0s instr=%08h actual=%b expected=%b", label, instr, actual, expected);
          fail_prints = fail_prints + 1;
        end
      end
    end
  endtask

  task automatic cmp2(
      input [255:0] label,
      input [31:0] instr,
      input [1:0] actual,
      input [1:0] expected
  );
    begin
      total = total + 1;
      if (actual === expected) begin
        passed = passed + 1;
      end else begin
        failed = failed + 1;
        if (fail_prints < 8) begin
          $display("FAIL %0s instr=%08h actual=%b expected=%b", label, instr, actual, expected);
          fail_prints = fail_prints + 1;
        end
      end
    end
  endtask

  task automatic cmp3(
      input [255:0] label,
      input [31:0] instr,
      input [2:0] actual,
      input [2:0] expected
  );
    begin
      total = total + 1;
      if (actual === expected) begin
        passed = passed + 1;
      end else begin
        failed = failed + 1;
        if (fail_prints < 8) begin
          $display("FAIL %0s instr=%08h actual=%b expected=%b", label, instr, actual, expected);
          fail_prints = fail_prints + 1;
        end
      end
    end
  endtask

  task automatic check_legal(
      input [255:0] label,
      input [31:0] instr,
      input        e_RegWriteD,
      input [2:0]  e_ImmSrcD,
      input        e_ALUSrcAD,
      input        e_ALUSrcBD,
      input [1:0]  e_MemRWD,
      input [2:0]  e_ResultSrcD,
      input        e_BranchD,
      input        e_JumpD,
      input        e_ALUResultSrcD,
      input [2:0]  e_ALUSelectD,
      input        e_SubArithD
  );
    begin
      InstrD = instr;
      #1;
      // Legal instructions: specification fully determines every output port.
      cmp1({label, ".IllegalInstrD"}, instr, IllegalInstrD, 1'b0);
      cmp1({label, ".RegWriteD"},     instr, RegWriteD,     e_RegWriteD);
      cmp3({label, ".ImmSrcD"},       instr, ImmSrcD,       e_ImmSrcD);
      cmp1({label, ".ALUSrcAD"},      instr, ALUSrcAD,      e_ALUSrcAD);
      cmp1({label, ".ALUSrcBD"},      instr, ALUSrcBD,      e_ALUSrcBD);
      cmp2({label, ".MemRWD"},        instr, MemRWD,        e_MemRWD);
      cmp3({label, ".ResultSrcD"},    instr, ResultSrcD,    e_ResultSrcD);
      cmp1({label, ".BranchD"},       instr, BranchD,       e_BranchD);
      cmp1({label, ".JumpD"},         instr, JumpD,         e_JumpD);
      cmp1({label, ".ALUResultSrcD"}, instr, ALUResultSrcD, e_ALUResultSrcD);
      cmp3({label, ".ALUSelectD"},    instr, ALUSelectD,    e_ALUSelectD);
      cmp1({label, ".SubArithD"},     instr, SubArithD,     e_SubArithD);
    end
  endtask

  task automatic check_illegal(
      input [255:0] label,
      input [31:0] instr
  );
    begin
      InstrD = instr;
      #1;
      // Illegal instructions: spec only requires Illegal plus suppression of side effects.
      cmp1({label, ".IllegalInstrD"}, instr, IllegalInstrD, 1'b1);
      cmp1({label, ".RegWriteD"},     instr, RegWriteD,     1'b0);
      cmp2({label, ".MemRWD"},        instr, MemRWD,        2'b00);
      cmp1({label, ".BranchD"},       instr, BranchD,       1'b0);
      cmp1({label, ".JumpD"},         instr, JumpD,         1'b0);
    end
  endtask

  integer i;
  logic [4:0] shamt5;
  logic [31:0] instr_tmp;

  initial begin
    passed = 0;
    failed = 0;
    total = 0;
    fail_prints = 0;
    InstrD = 32'h00000000;

    // Sample examples from the specification.
    check_legal("sample_add", enc_r(7'b0000000, 5'd3, 5'd2, 3'b000, 5'd1, 7'b0110011),
                1'b1, 3'b000, 1'b0, 1'b0, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);
    check_legal("sample_sub", enc_r(7'b0100000, 5'd3, 5'd2, 3'b000, 5'd1, 7'b0110011),
                1'b1, 3'b000, 1'b0, 1'b0, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b000, 1'b1);
    check_legal("sample_lw",  enc_i(12'h000, 5'd2, 3'b010, 5'd1, 7'b0000011),
                1'b1, 3'b000, 1'b0, 1'b1, 2'b10, 3'b001, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);
    check_legal("sample_sw",  enc_s(12'h000, 5'd1, 5'd2, 3'b010, 7'b0100011),
                1'b0, 3'b001, 1'b0, 1'b1, 2'b01, 3'b000, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);
    check_legal("sample_beq", enc_b(13'h0000, 5'd2, 5'd1, 3'b000, 7'b1100011),
                1'b0, 3'b010, 1'b1, 1'b1, 2'b00, 3'b000, 1'b1, 1'b0, 1'b0, 3'b000, 1'b0);
    check_illegal("sample_illegal_opcode", 32'h0000007f);

    // Load class: all legal funct3 values and multiple immediate corner patterns.
    check_legal("lb_minimm",  enc_i(12'h800, 5'd4, 3'b000, 5'd5, 7'b0000011),
                1'b1, 3'b000, 1'b0, 1'b1, 2'b10, 3'b001, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);
    check_legal("lh_zero",    enc_i(12'h000, 5'd4, 3'b001, 5'd5, 7'b0000011),
                1'b1, 3'b000, 1'b0, 1'b1, 2'b10, 3'b001, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);
    check_legal("lw_maximm",  enc_i(12'h7ff, 5'd4, 3'b010, 5'd5, 7'b0000011),
                1'b1, 3'b000, 1'b0, 1'b1, 2'b10, 3'b001, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);
    check_legal("lbu_all1",   enc_i(12'hfff, 5'd4, 3'b100, 5'd5, 7'b0000011),
                1'b1, 3'b000, 1'b0, 1'b1, 2'b10, 3'b001, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);
    check_legal("lhu_misc",   enc_i(12'h155, 5'd4, 3'b101, 5'd5, 7'b0000011),
                1'b1, 3'b000, 1'b0, 1'b1, 2'b10, 3'b001, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);
    check_illegal("load_bad_f3_011", enc_i(12'h000, 5'd1, 3'b011, 5'd2, 7'b0000011));
    check_illegal("load_bad_f3_110", enc_i(12'h000, 5'd1, 3'b110, 5'd2, 7'b0000011));
    check_illegal("load_bad_f3_111", enc_i(12'h000, 5'd1, 3'b111, 5'd2, 7'b0000011));

    // Store class: all legal funct3 values and fragmented immediate corners.
    check_legal("sb_zero",    enc_s(12'h000, 5'd6, 5'd7, 3'b000, 7'b0100011),
                1'b0, 3'b001, 1'b0, 1'b1, 2'b01, 3'b000, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);
    check_legal("sh_minimm",  enc_s(12'h800, 5'd6, 5'd7, 3'b001, 7'b0100011),
                1'b0, 3'b001, 1'b0, 1'b1, 2'b01, 3'b000, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);
    check_legal("sw_all1",    enc_s(12'hfff, 5'd6, 5'd7, 3'b010, 7'b0100011),
                1'b0, 3'b001, 1'b0, 1'b1, 2'b01, 3'b000, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);
    check_illegal("store_bad_f3_011", enc_s(12'h123, 5'd6, 5'd7, 3'b011, 7'b0100011));
    check_illegal("store_bad_f3_100", enc_s(12'h123, 5'd6, 5'd7, 3'b100, 7'b0100011));
    check_illegal("store_bad_f3_101", enc_s(12'h123, 5'd6, 5'd7, 3'b101, 7'b0100011));
    check_illegal("store_bad_f3_110", enc_s(12'h123, 5'd6, 5'd7, 3'b110, 7'b0100011));
    check_illegal("store_bad_f3_111", enc_s(12'h123, 5'd6, 5'd7, 3'b111, 7'b0100011));

    // Branch class: all legal funct3 values, illegal funct3 values, and fragmented immediates.
    check_legal("beq_zero",   enc_b(13'h0000, 5'd2, 5'd1, 3'b000, 7'b1100011),
                1'b0, 3'b010, 1'b1, 1'b1, 2'b00, 3'b000, 1'b1, 1'b0, 1'b0, 3'b000, 1'b0);
    check_legal("bne_neg",    enc_b(13'h1ffe, 5'd2, 5'd1, 3'b001, 7'b1100011),
                1'b0, 3'b010, 1'b1, 1'b1, 2'b00, 3'b000, 1'b1, 1'b0, 1'b0, 3'b000, 1'b0);
    check_legal("blt_pos",    enc_b(13'h07fe, 5'd2, 5'd1, 3'b100, 7'b1100011),
                1'b0, 3'b010, 1'b1, 1'b1, 2'b00, 3'b000, 1'b1, 1'b0, 1'b0, 3'b000, 1'b0);
    check_legal("bge_misc",   enc_b(13'h0554, 5'd2, 5'd1, 3'b101, 7'b1100011),
                1'b0, 3'b010, 1'b1, 1'b1, 2'b00, 3'b000, 1'b1, 1'b0, 1'b0, 3'b000, 1'b0);
    check_legal("bltu_misc",  enc_b(13'h02aa, 5'd2, 5'd1, 3'b110, 7'b1100011),
                1'b0, 3'b010, 1'b1, 1'b1, 2'b00, 3'b000, 1'b1, 1'b0, 1'b0, 3'b000, 1'b0);
    check_legal("bgeu_misc",  enc_b(13'h1000, 5'd2, 5'd1, 3'b111, 7'b1100011),
                1'b0, 3'b010, 1'b1, 1'b1, 2'b00, 3'b000, 1'b1, 1'b0, 1'b0, 3'b000, 1'b0);
    check_illegal("branch_bad_f3_010", enc_b(13'h0000, 5'd2, 5'd1, 3'b010, 7'b1100011));
    check_illegal("branch_bad_f3_011", enc_b(13'h0000, 5'd2, 5'd1, 3'b011, 7'b1100011));

    // U-type and jump classes.
    check_legal("auipc_zero", enc_u(20'h00000, 5'd1, 7'b0010111),
                1'b1, 3'b100, 1'b1, 1'b1, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);
    check_legal("auipc_all1", enc_u(20'hfffff, 5'd31, 7'b0010111),
                1'b1, 3'b100, 1'b1, 1'b1, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);
    check_legal("lui_zero",   enc_u(20'h00000, 5'd1, 7'b0110111),
                1'b1, 3'b100, 1'b0, 1'b1, 2'b00, 3'b000, 1'b0, 1'b0, 1'b1, 3'b000, 1'b0);
    check_legal("lui_all1",   enc_u(20'hfffff, 5'd31, 7'b0110111),
                1'b1, 3'b100, 1'b0, 1'b1, 2'b00, 3'b000, 1'b0, 1'b0, 1'b1, 3'b000, 1'b0);
    check_legal("jal_zero",   enc_j(21'h000000, 5'd1, 7'b1101111),
                1'b1, 3'b011, 1'b1, 1'b1, 2'b00, 3'b000, 1'b0, 1'b1, 1'b1, 3'b000, 1'b0);
    check_legal("jal_frag",   enc_j(21'h155554, 5'd2, 7'b1101111),
                1'b1, 3'b011, 1'b1, 1'b1, 2'b00, 3'b000, 1'b0, 1'b1, 1'b1, 3'b000, 1'b0);
    check_legal("jal_neg",    enc_j(21'h1ffffe, 5'd3, 7'b1101111),
                1'b1, 3'b011, 1'b1, 1'b1, 2'b00, 3'b000, 1'b0, 1'b1, 1'b1, 3'b000, 1'b0);
    check_legal("jalr_ok",    enc_i(12'h123, 5'd4, 3'b000, 5'd5, 7'b1100111),
                1'b1, 3'b000, 1'b0, 1'b1, 2'b00, 3'b000, 1'b0, 1'b1, 1'b1, 3'b000, 1'b0);
    check_illegal("jalr_bad_f3_001", enc_i(12'h123, 5'd4, 3'b001, 5'd5, 7'b1100111));
    check_illegal("jalr_bad_f3_111", enc_i(12'h123, 5'd4, 3'b111, 5'd5, 7'b1100111));

    // I-type ALU class: all defined operations, signed compare classes, legal shift-immediates,
    // and illegal shift encodings. Shamt boundaries 0 and 31 exercise RV32 masking width.
    check_legal("addi_zero",  enc_i(12'h000, 5'd1, 3'b000, 5'd2, 7'b0010011),
                1'b1, 3'b000, 1'b0, 1'b1, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);
    check_legal("slti_min",   enc_i(12'h800, 5'd1, 3'b010, 5'd2, 7'b0010011),
                1'b1, 3'b000, 1'b0, 1'b1, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b010, 1'b1);
    check_legal("sltiu_all1", enc_i(12'hfff, 5'd1, 3'b011, 5'd2, 7'b0010011),
                1'b1, 3'b000, 1'b0, 1'b1, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b011, 1'b1);
    check_legal("xori_misc",  enc_i(12'h55a, 5'd1, 3'b100, 5'd2, 7'b0010011),
                1'b1, 3'b000, 1'b0, 1'b1, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b100, 1'b0);
    check_legal("ori_misc",   enc_i(12'ha55, 5'd1, 3'b110, 5'd2, 7'b0010011),
                1'b1, 3'b000, 1'b0, 1'b1, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b110, 1'b0);
    check_legal("andi_misc",  enc_i(12'h0f0, 5'd1, 3'b111, 5'd2, 7'b0010011),
                1'b1, 3'b000, 1'b0, 1'b1, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b111, 1'b0);

    shamt5 = 5'd0;
    instr_tmp = {7'b0000000, shamt5, 5'd1, 3'b001, 5'd2, 7'b0010011};
    check_legal("slli_0", instr_tmp,
                1'b1, 3'b000, 1'b0, 1'b1, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b001, 1'b0);

    shamt5 = 5'd31;
    instr_tmp = {7'b0000000, shamt5, 5'd1, 3'b001, 5'd2, 7'b0010011};
    check_legal("slli_31", instr_tmp,
                1'b1, 3'b000, 1'b0, 1'b1, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b001, 1'b0);

    shamt5 = 5'd0;
    instr_tmp = {7'b0000000, shamt5, 5'd1, 3'b101, 5'd2, 7'b0010011};
    check_legal("srli_0", instr_tmp,
                1'b1, 3'b000, 1'b0, 1'b1, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b101, 1'b0);

    shamt5 = 5'd31;
    instr_tmp = {7'b0100000, shamt5, 5'd1, 3'b101, 5'd2, 7'b0010011};
    check_legal("srai_31", instr_tmp,
                1'b1, 3'b000, 1'b0, 1'b1, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b101, 1'b1);

    shamt5 = 5'd17;
    instr_tmp = {7'b0100000, shamt5, 5'd1, 3'b001, 5'd2, 7'b0010011};
    check_illegal("slli_bad_funct7", instr_tmp);

    shamt5 = 5'd8;
    instr_tmp = {7'b0000001, shamt5, 5'd1, 3'b001, 5'd2, 7'b0010011};
    check_illegal("slli_bad_nonzero_funct7", instr_tmp);

    shamt5 = 5'd9;
    instr_tmp = {7'b0010000, shamt5, 5'd1, 3'b101, 5'd2, 7'b0010011};
    check_illegal("srxi_bad_funct7_mid", instr_tmp);

    shamt5 = 5'd31;
    instr_tmp = {7'b1111111, shamt5, 5'd1, 3'b101, 5'd2, 7'b0010011};
    check_illegal("srxi_bad_funct7_all1", instr_tmp);

    // R-type ALU class: all defined operation classes, strict funct7 legality, and signed compare classes.
    check_legal("add",  enc_r(7'b0000000, 5'd3, 5'd2, 3'b000, 5'd1, 7'b0110011),
                1'b1, 3'b000, 1'b0, 1'b0, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);
    check_legal("sub",  enc_r(7'b0100000, 5'd3, 5'd2, 3'b000, 5'd1, 7'b0110011),
                1'b1, 3'b000, 1'b0, 1'b0, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b000, 1'b1);
    check_legal("sll",  enc_r(7'b0000000, 5'd3, 5'd2, 3'b001, 5'd1, 7'b0110011),
                1'b1, 3'b000, 1'b0, 1'b0, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b001, 1'b0);
    check_legal("slt",  enc_r(7'b0000000, 5'd3, 5'd2, 3'b010, 5'd1, 7'b0110011),
                1'b1, 3'b000, 1'b0, 1'b0, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b010, 1'b1);
    check_legal("sltu", enc_r(7'b0000000, 5'd3, 5'd2, 3'b011, 5'd1, 7'b0110011),
                1'b1, 3'b000, 1'b0, 1'b0, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b011, 1'b1);
    check_legal("xor",  enc_r(7'b0000000, 5'd3, 5'd2, 3'b100, 5'd1, 7'b0110011),
                1'b1, 3'b000, 1'b0, 1'b0, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b100, 1'b0);
    check_legal("srl",  enc_r(7'b0000000, 5'd3, 5'd2, 3'b101, 5'd1, 7'b0110011),
                1'b1, 3'b000, 1'b0, 1'b0, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b101, 1'b0);
    check_legal("sra",  enc_r(7'b0100000, 5'd3, 5'd2, 3'b101, 5'd1, 7'b0110011),
                1'b1, 3'b000, 1'b0, 1'b0, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b101, 1'b1);
    check_legal("or",   enc_r(7'b0000000, 5'd3, 5'd2, 3'b110, 5'd1, 7'b0110011),
                1'b1, 3'b000, 1'b0, 1'b0, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b110, 1'b0);
    check_legal("and",  enc_r(7'b0000000, 5'd3, 5'd2, 3'b111, 5'd1, 7'b0110011),
                1'b1, 3'b000, 1'b0, 1'b0, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b111, 1'b0);

    check_illegal("r_bad_sub_f7",  enc_r(7'b0000001, 5'd3, 5'd2, 3'b000, 5'd1, 7'b0110011));
    check_illegal("r_bad_sll_f7",  enc_r(7'b0100000, 5'd3, 5'd2, 3'b001, 5'd1, 7'b0110011));
    check_illegal("r_bad_slt_f7",  enc_r(7'b0100000, 5'd3, 5'd2, 3'b010, 5'd1, 7'b0110011));
    check_illegal("r_bad_sltu_f7", enc_r(7'b0100000, 5'd3, 5'd2, 3'b011, 5'd1, 7'b0110011));
    check_illegal("r_bad_xor_f7",  enc_r(7'b0100000, 5'd3, 5'd2, 3'b100, 5'd1, 7'b0110011));
    check_illegal("r_bad_or_f7",   enc_r(7'b0100000, 5'd3, 5'd2, 3'b110, 5'd1, 7'b0110011));
    check_illegal("r_bad_and_f7",  enc_r(7'b0100000, 5'd3, 5'd2, 3'b111, 5'd1, 7'b0110011));
    check_illegal("r_bad_all1_f7", enc_r(7'b1111111, 5'd31, 5'd31, 3'b101, 5'd31, 7'b0110011));

    // Unsupported/system/extension opcodes are illegal per strict RV32I decoder spec.
    check_illegal("fence",   32'h0000000f);
    check_illegal("fence_i", 32'h0000100f);
    check_illegal("ecall",   32'h00000073);
    check_illegal("ebreak",  32'h00100073);
    check_illegal("csr",     32'h30511073);

    // Additional illegal opcodes and corner patterns.
    check_illegal("opcode_0000000",    32'h00000000);
    check_illegal("opcode_1111111",    32'h0000007f);
    check_illegal("opcode_1111111_all1", 32'hffffffff);
    check_illegal("misc_mem", enc_i(12'h000, 5'd0, 3'b000, 5'd0, 7'b0001111));

    $display("A1_CHECKS passed=%0d failed=%0d total=%0d", passed, failed, total);
    if (failed == 0 && total > 0) $display("PASS");
    else $display("FAIL");
    $finish;
  end

endmodule
