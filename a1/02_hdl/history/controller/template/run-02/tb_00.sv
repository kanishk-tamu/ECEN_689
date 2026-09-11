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

  task automatic check_field_1(
      input string label,
      input logic actual,
      input logic expected,
      input logic [31:0] instr
  );
    begin
      total = total + 1;
      if (actual === expected) begin
        passed = passed + 1;
      end else begin
        failed = failed + 1;
        if (fail_prints < 8) begin
          $display("FAIL %s instr=%08h actual=%0b expected=%0b", label, instr, actual, expected);
          fail_prints = fail_prints + 1;
        end
      end
    end
  endtask

  task automatic check_field_2(
      input string label,
      input logic [1:0] actual,
      input logic [1:0] expected,
      input logic [31:0] instr
  );
    begin
      total = total + 1;
      if (actual === expected) begin
        passed = passed + 1;
      end else begin
        failed = failed + 1;
        if (fail_prints < 8) begin
          $display("FAIL %s instr=%08h actual=%0h expected=%0h", label, instr, actual, expected);
          fail_prints = fail_prints + 1;
        end
      end
    end
  endtask

  task automatic check_field_3(
      input string label,
      input logic [2:0] actual,
      input logic [2:0] expected,
      input logic [31:0] instr
  );
    begin
      total = total + 1;
      if (actual === expected) begin
        passed = passed + 1;
      end else begin
        failed = failed + 1;
        if (fail_prints < 8) begin
          $display("FAIL %s instr=%08h actual=%0h expected=%0h", label, instr, actual, expected);
          fail_prints = fail_prints + 1;
        end
      end
    end
  endtask

  function automatic [31:0] enc_r(
      input logic [6:0] funct7,
      input logic [4:0] rs2,
      input logic [4:0] rs1,
      input logic [2:0] funct3,
      input logic [4:0] rd,
      input logic [6:0] opcode
  );
    begin
      enc_r = {funct7, rs2, rs1, funct3, rd, opcode};
    end
  endfunction

  function automatic [31:0] enc_i(
      input logic [11:0] imm12,
      input logic [4:0]  rs1,
      input logic [2:0]  funct3,
      input logic [4:0]  rd,
      input logic [6:0]  opcode
  );
    begin
      enc_i = {imm12, rs1, funct3, rd, opcode};
    end
  endfunction

  function automatic [31:0] enc_s(
      input logic [11:0] imm12,
      input logic [4:0]  rs2,
      input logic [4:0]  rs1,
      input logic [2:0]  funct3,
      input logic [6:0]  opcode
  );
    begin
      enc_s = {imm12[11:5], rs2, rs1, funct3, imm12[4:0], opcode};
    end
  endfunction

  function automatic [31:0] enc_b(
      input logic [12:0] imm13,
      input logic [4:0]  rs2,
      input logic [4:0]  rs1,
      input logic [2:0]  funct3,
      input logic [6:0]  opcode
  );
    begin
      enc_b = {imm13[12], imm13[10:5], rs2, rs1, funct3, imm13[4:1], imm13[11], opcode};
    end
  endfunction

  function automatic [31:0] enc_u(
      input logic [19:0] imm20,
      input logic [4:0]  rd,
      input logic [6:0]  opcode
  );
    begin
      enc_u = {imm20, rd, opcode};
    end
  endfunction

  function automatic [31:0] enc_j(
      input logic [20:0] imm21,
      input logic [4:0]  rd,
      input logic [6:0]  opcode
  );
    begin
      enc_j = {imm21[20], imm21[10:1], imm21[11], imm21[19:12], rd, opcode};
    end
  endfunction

  task automatic expect_legal(
      input string      name,
      input logic [31:0] instr,
      input logic        exp_RegWriteD,
      input logic [2:0]  exp_ImmSrcD,
      input logic        exp_ALUSrcAD,
      input logic        exp_ALUSrcBD,
      input logic [1:0]  exp_MemRWD,
      input logic [2:0]  exp_ResultSrcD,
      input logic        exp_BranchD,
      input logic        exp_JumpD,
      input logic        exp_ALUResultSrcD,
      input logic [2:0]  exp_ALUSelectD,
      input logic        exp_SubArithD
  );
    begin
      InstrD = instr;
      #1;
      check_field_1({name, ".IllegalInstrD"}, IllegalInstrD, 1'b0, instr);
      check_field_1({name, ".RegWriteD"},     RegWriteD,     exp_RegWriteD,     instr);
      check_field_3({name, ".ImmSrcD"},       ImmSrcD,       exp_ImmSrcD,       instr);
      check_field_1({name, ".ALUSrcAD"},      ALUSrcAD,      exp_ALUSrcAD,      instr);
      check_field_1({name, ".ALUSrcBD"},      ALUSrcBD,      exp_ALUSrcBD,      instr);
      check_field_2({name, ".MemRWD"},        MemRWD,        exp_MemRWD,        instr);
      check_field_3({name, ".ResultSrcD"},    ResultSrcD,    exp_ResultSrcD,    instr);
      check_field_1({name, ".BranchD"},       BranchD,       exp_BranchD,       instr);
      check_field_1({name, ".JumpD"},         JumpD,         exp_JumpD,         instr);
      check_field_1({name, ".ALUResultSrcD"}, ALUResultSrcD, exp_ALUResultSrcD, instr);
      check_field_3({name, ".ALUSelectD"},    ALUSelectD,    exp_ALUSelectD,    instr);
      check_field_1({name, ".SubArithD"},     SubArithD,     exp_SubArithD,     instr);
    end
  endtask

  task automatic expect_illegal(
      input string       name,
      input logic [31:0] instr
  );
    begin
      InstrD = instr;
      #1;
      check_field_1({name, ".IllegalInstrD"}, IllegalInstrD, 1'b1,  instr);
      check_field_1({name, ".RegWriteD"},     RegWriteD,     1'b0,  instr);
      check_field_2({name, ".MemRWD"},        MemRWD,        2'b00, instr);
      check_field_1({name, ".BranchD"},       BranchD,       1'b0,  instr);
      check_field_1({name, ".JumpD"},         JumpD,         1'b0,  instr);
    end
  endtask

  initial begin
    passed = 0;
    failed = 0;
    total = 0;
    fail_prints = 0;
    InstrD = 32'h00000013;

    /* Watchdog for combinational TB */
    fork
      begin
        #10000;
        $display("FAIL");
        $finish;
      end
    join_none

    /* Sample usage coverage from spec */
    expect_legal("sample_add",
      enc_r(7'b0000000, 5'd3, 5'd2, 3'b000, 5'd1, 7'b0110011),
      1'b1, 3'b000, 1'b0, 1'b0, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);

    expect_legal("sample_sub",
      enc_r(7'b0100000, 5'd3, 5'd2, 3'b000, 5'd1, 7'b0110011),
      1'b1, 3'b000, 1'b0, 1'b0, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b000, 1'b1);

    expect_legal("sample_lw",
      enc_i(12'h000, 5'd2, 3'b010, 5'd1, 7'b0000011),
      1'b1, 3'b000, 1'b0, 1'b1, 2'b10, 3'b001, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);

    expect_legal("sample_sw",
      enc_s(12'h000, 5'd1, 5'd2, 3'b010, 7'b0100011),
      1'b0, 3'b001, 1'b0, 1'b1, 2'b01, 3'b000, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);

    expect_legal("sample_beq",
      enc_b(13'h0000, 5'd2, 5'd1, 3'b000, 7'b1100011),
      1'b0, 3'b010, 1'b1, 1'b1, 2'b00, 3'b000, 1'b1, 1'b0, 1'b0, 3'b000, 1'b0);

    expect_illegal("sample_illegal_opcode", 32'h0000007f);

    /* Load class: all legal funct3 values + illegal encodings, varied immediates */
    expect_legal("lb_negimm",
      enc_i(12'h800, 5'd31, 3'b000, 5'd0, 7'b0000011),
      1'b1, 3'b000, 1'b0, 1'b1, 2'b10, 3'b001, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);

    expect_legal("lh_zeroimm",
      enc_i(12'h000, 5'd1, 3'b001, 5'd2, 7'b0000011),
      1'b1, 3'b000, 1'b0, 1'b1, 2'b10, 3'b001, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);

    expect_legal("lw_posimm",
      enc_i(12'h7ff, 5'd2, 3'b010, 5'd3, 7'b0000011),
      1'b1, 3'b000, 1'b0, 1'b1, 2'b10, 3'b001, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);

    expect_legal("lbu_allonesimm",
      enc_i(12'hfff, 5'd3, 3'b100, 5'd4, 7'b0000011),
      1'b1, 3'b000, 1'b0, 1'b1, 2'b10, 3'b001, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);

    expect_legal("lhu_misc",
      enc_i(12'h123, 5'd4, 3'b101, 5'd5, 7'b0000011),
      1'b1, 3'b000, 1'b0, 1'b1, 2'b10, 3'b001, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);

    expect_illegal("load_funct3_011",
      enc_i(12'h000, 5'd2, 3'b011, 5'd1, 7'b0000011));

    expect_illegal("load_funct3_110",
      enc_i(12'h000, 5'd2, 3'b110, 5'd1, 7'b0000011));

    expect_illegal("load_funct3_111",
      enc_i(12'h000, 5'd2, 3'b111, 5'd1, 7'b0000011));

    /* Store class: legal and illegal funct3, fragmented S immediates */
    expect_legal("sb_fragimm",
      enc_s(12'h5a5, 5'd7, 5'd8, 3'b000, 7'b0100011),
      1'b0, 3'b001, 1'b0, 1'b1, 2'b01, 3'b000, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);

    expect_legal("sh_zeroimm",
      enc_s(12'h000, 5'd9, 5'd10, 3'b001, 7'b0100011),
      1'b0, 3'b001, 1'b0, 1'b1, 2'b01, 3'b000, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);

    expect_legal("sw_negimm",
      enc_s(12'hfff, 5'd11, 5'd12, 3'b010, 7'b0100011),
      1'b0, 3'b001, 1'b0, 1'b1, 2'b01, 3'b000, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);

    expect_illegal("store_funct3_011",
      enc_s(12'h000, 5'd1, 5'd2, 3'b011, 7'b0100011));

    expect_illegal("store_funct3_100",
      enc_s(12'h000, 5'd1, 5'd2, 3'b100, 7'b0100011));

    expect_illegal("store_funct3_111",
      enc_s(12'h000, 5'd1, 5'd2, 3'b111, 7'b0100011));

    /* Branch class: all legal funct3 plus illegal, fragmented B immediates */
    expect_legal("beq_minlike",
      enc_b(13'b1_000000_0000_0, 5'd2, 5'd1, 3'b000, 7'b1100011),
      1'b0, 3'b010, 1'b1, 1'b1, 2'b00, 3'b000, 1'b1, 1'b0, 1'b0, 3'b000, 1'b0);

    expect_legal("bne_misc",
      enc_b(13'h055, 5'd3, 5'd4, 3'b001, 7'b1100011),
      1'b0, 3'b010, 1'b1, 1'b1, 2'b00, 3'b000, 1'b1, 1'b0, 1'b0, 3'b000, 1'b0);

    expect_legal("blt",
      enc_b(13'h1aa, 5'd5, 5'd6, 3'b100, 7'b1100011),
      1'b0, 3'b010, 1'b1, 1'b1, 2'b00, 3'b000, 1'b1, 1'b0, 1'b0, 3'b000, 1'b0);

    expect_legal("bge",
      enc_b(13'h0fe, 5'd7, 5'd8, 3'b101, 7'b1100011),
      1'b0, 3'b010, 1'b1, 1'b1, 2'b00, 3'b000, 1'b1, 1'b0, 1'b0, 3'b000, 1'b0);

    expect_legal("bltu",
      enc_b(13'h124, 5'd9, 5'd10, 3'b110, 7'b1100011),
      1'b0, 3'b010, 1'b1, 1'b1, 2'b00, 3'b000, 1'b1, 1'b0, 1'b0, 3'b000, 1'b0);

    expect_legal("bgeu",
      enc_b(13'h7fe, 5'd11, 5'd12, 3'b111, 7'b1100011),
      1'b0, 3'b010, 1'b1, 1'b1, 2'b00, 3'b000, 1'b1, 1'b0, 1'b0, 3'b000, 1'b0);

    expect_illegal("branch_funct3_010",
      enc_b(13'h000, 5'd2, 5'd1, 3'b010, 7'b1100011));

    expect_illegal("branch_funct3_011",
      enc_b(13'h000, 5'd2, 5'd1, 3'b011, 7'b1100011));

    /* Jumps and upper immediates */
    expect_legal("jalr_legal",
      enc_i(12'h123, 5'd2, 3'b000, 5'd1, 7'b1100111),
      1'b1, 3'b000, 1'b0, 1'b1, 2'b00, 3'b000, 1'b0, 1'b1, 1'b1, 3'b000, 1'b0);

    expect_illegal("jalr_bad_funct3_001",
      enc_i(12'h123, 5'd2, 3'b001, 5'd1, 7'b1100111));

    expect_legal("jal_fragmented_imm",
      enc_j(21'h15555, 5'd1, 7'b1101111),
      1'b1, 3'b011, 1'b1, 1'b1, 2'b00, 3'b000, 1'b0, 1'b1, 1'b1, 3'b000, 1'b0);

    expect_legal("jal_zero_imm",
      enc_j(21'h00000, 5'd0, 7'b1101111),
      1'b1, 3'b011, 1'b1, 1'b1, 2'b00, 3'b000, 1'b0, 1'b1, 1'b1, 3'b000, 1'b0);

    expect_legal("lui_allones_upper",
      enc_u(20'hfffff, 5'd31, 7'b0110111),
      1'b1, 3'b100, 1'b0, 1'b1, 2'b00, 3'b000, 1'b0, 1'b0, 1'b1, 3'b000, 1'b0);

    expect_legal("auipc_zero_upper",
      enc_u(20'h00000, 5'd1, 7'b0010111),
      1'b1, 3'b100, 1'b1, 1'b1, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);

    /* I-type ALU: all classes, signed boundaries, zero, all ones, shift masking/legality */
    expect_legal("addi_zero",
      enc_i(12'h000, 5'd2, 3'b000, 5'd1, 7'b0010011),
      1'b1, 3'b000, 1'b0, 1'b1, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);

    expect_legal("slti_neg1",
      enc_i(12'hfff, 5'd2, 3'b010, 5'd1, 7'b0010011),
      1'b1, 3'b000, 1'b0, 1'b1, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b010, 1'b1);

    expect_legal("sltiu_minimm",
      enc_i(12'h800, 5'd2, 3'b011, 5'd1, 7'b0010011),
      1'b1, 3'b000, 1'b0, 1'b1, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b011, 1'b1);

    expect_legal("xori_allones",
      enc_i(12'hfff, 5'd2, 3'b100, 5'd1, 7'b0010011),
      1'b1, 3'b000, 1'b0, 1'b1, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b100, 1'b0);

    expect_legal("ori_misc",
      enc_i(12'h123, 5'd2, 3'b110, 5'd1, 7'b0010011),
      1'b1, 3'b000, 1'b0, 1'b1, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b110, 1'b0);

    expect_legal("andi_misc",
      enc_i(12'h456, 5'd2, 3'b111, 5'd1, 7'b0010011),
      1'b1, 3'b000, 1'b0, 1'b1, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b111, 1'b0);

    expect_legal("slli_shamt0",
      enc_i({7'b0000000,5'd0}, 5'd2, 3'b001, 5'd1, 7'b0010011),
      1'b1, 3'b000, 1'b0, 1'b1, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b001, 1'b0);

    expect_legal("slli_shamt31_masked",
      enc_i({7'b0000000,5'd31}, 5'd2, 3'b001, 5'd1, 7'b0010011),
      1'b1, 3'b000, 1'b0, 1'b1, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b001, 1'b0);

    expect_legal("srli_shamt31",
      enc_i({7'b0000000,5'd31}, 5'd2, 3'b101, 5'd1, 7'b0010011),
      1'b1, 3'b000, 1'b0, 1'b1, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b101, 1'b0);

    expect_legal("srai_shamt1",
      enc_i({7'b0100000,5'd1}, 5'd2, 3'b101, 5'd1, 7'b0010011),
      1'b1, 3'b000, 1'b0, 1'b1, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b101, 1'b1);

    expect_illegal("slli_bad_upper",
      enc_i({7'b0100000,5'd1}, 5'd2, 3'b001, 5'd1, 7'b0010011));

    expect_illegal("srli_srai_bad_upper",
      enc_i({7'b1111111,5'd31}, 5'd2, 3'b101, 5'd1, 7'b0010011));

    /* R-type ALU: every funct3 class, legal funct7 variants, illegal funct7 cases */
    expect_legal("add",
      enc_r(7'b0000000, 5'd3, 5'd2, 3'b000, 5'd1, 7'b0110011),
      1'b1, 3'b000, 1'b0, 1'b0, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0);

    expect_legal("sub",
      enc_r(7'b0100000, 5'd3, 5'd2, 3'b000, 5'd1, 7'b0110011),
      1'b1, 3'b000, 1'b0, 1'b0, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b000, 1'b1);

    expect_legal("sll",
      enc_r(7'b0000000, 5'd3, 5'd2, 3'b001, 5'd1, 7'b0110011),
      1'b1, 3'b000, 1'b0, 1'b0, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b001, 1'b0);

    expect_legal("slt",
      enc_r(7'b0000000, 5'd3, 5'd2, 3'b010, 5'd1, 7'b0110011),
      1'b1, 3'b000, 1'b0, 1'b0, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b010, 1'b1);

    expect_legal("sltu",
      enc_r(7'b0000000, 5'd3, 5'd2, 3'b011, 5'd1, 7'b0110011),
      1'b1, 3'b000, 1'b0, 1'b0, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b011, 1'b1);

    expect_legal("xor",
      enc_r(7'b0000000, 5'd3, 5'd2, 3'b100, 5'd1, 7'b0110011),
      1'b1, 3'b000, 1'b0, 1'b0, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b100, 1'b0);

    expect_legal("srl",
      enc_r(7'b0000000, 5'd3, 5'd2, 3'b101, 5'd1, 7'b0110011),
      1'b1, 3'b000, 1'b0, 1'b0, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b101, 1'b0);

    expect_legal("sra",
      enc_r(7'b0100000, 5'd3, 5'd2, 3'b101, 5'd1, 7'b0110011),
      1'b1, 3'b000, 1'b0, 1'b0, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b101, 1'b1);

    expect_legal("or",
      enc_r(7'b0000000, 5'd3, 5'd2, 3'b110, 5'd1, 7'b0110011),
      1'b1, 3'b000, 1'b0, 1'b0, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b110, 1'b0);

    expect_legal("and",
      enc_r(7'b0000000, 5'd3, 5'd2, 3'b111, 5'd1, 7'b0110011),
      1'b1, 3'b000, 1'b0, 1'b0, 2'b00, 3'b000, 1'b0, 1'b0, 1'b0, 3'b111, 1'b0);

    expect_illegal("rtype_bad_funct7_add",
      enc_r(7'b0000001, 5'd3, 5'd2, 3'b000, 5'd1, 7'b0110011));

    expect_illegal("rtype_bad_funct7_sll",
      enc_r(7'b0100000, 5'd3, 5'd2, 3'b001, 5'd1, 7'b0110011));

    expect_illegal("rtype_bad_funct7_slt",
      enc_r(7'b0100000, 5'd3, 5'd2, 3'b010, 5'd1, 7'b0110011));

    expect_illegal("rtype_bad_funct7_sltu",
      enc_r(7'b0100000, 5'd3, 5'd2, 3'b011, 5'd1, 7'b0110011));

    expect_illegal("rtype_bad_funct7_xor",
      enc_r(7'b0100000, 5'd3, 5'd2, 3'b100, 5'd1, 7'b0110011));

    expect_illegal("rtype_bad_funct7_or",
      enc_r(7'b0100000, 5'd3, 5'd2, 3'b110, 5'd1, 7'b0110011));

    expect_illegal("rtype_bad_funct7_and",
      enc_r(7'b0100000, 5'd3, 5'd2, 3'b111, 5'd1, 7'b0110011));

    /* Unsupported/other extension/system opcodes explicitly illegal by spec */
    expect_illegal("fence",
      enc_i(12'h000, 5'd0, 3'b000, 5'd0, 7'b0001111));

    expect_illegal("fence_i",
      enc_i(12'h000, 5'd0, 3'b001, 5'd0, 7'b0001111));

    expect_illegal("ecall",
      32'h00000073);

    expect_illegal("ebreak",
      32'h00100073);

    expect_illegal("csr_rw_like",
      enc_i(12'h001, 5'd2, 3'b001, 5'd1, 7'b1110011));

    expect_illegal("misc_mem_unknown_opcode",
      32'hffffffff);

    $display("A1_CHECKS passed=%0d failed=%0d total=%0d", passed, failed, total);
    if ((failed == 0) && (total > 0))
      $display("PASS");
    else
      $display("FAIL");
    $finish;
  end

endmodule
