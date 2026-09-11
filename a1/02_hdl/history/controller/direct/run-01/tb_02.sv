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

  function automatic [31:0] mk_r(
      input logic [6:0] funct7,
      input logic [4:0] rs2,
      input logic [4:0] rs1,
      input logic [2:0] funct3,
      input logic [4:0] rd,
      input logic [6:0] opcode
  );
    begin
      mk_r = {funct7, rs2, rs1, funct3, rd, opcode};
    end
  endfunction

  function automatic [31:0] mk_i(
      input logic [11:0] imm12,
      input logic [4:0]  rs1,
      input logic [2:0]  funct3,
      input logic [4:0]  rd,
      input logic [6:0]  opcode
  );
    begin
      mk_i = {imm12, rs1, funct3, rd, opcode};
    end
  endfunction

  function automatic [31:0] mk_s(
      input logic [11:0] imm12,
      input logic [4:0]  rs2,
      input logic [4:0]  rs1,
      input logic [2:0]  funct3,
      input logic [6:0]  opcode
  );
    begin
      mk_s = {imm12[11:5], rs2, rs1, funct3, imm12[4:0], opcode};
    end
  endfunction

  function automatic [31:0] mk_b(
      input logic [12:0] imm13,
      input logic [4:0]  rs2,
      input logic [4:0]  rs1,
      input logic [2:0]  funct3,
      input logic [6:0]  opcode
  );
    begin
      mk_b = {imm13[12], imm13[10:5], rs2, rs1, funct3, imm13[4:1], imm13[11], opcode};
    end
  endfunction

  function automatic [31:0] mk_u(
      input logic [19:0] imm20,
      input logic [4:0]  rd,
      input logic [6:0]  opcode
  );
    begin
      mk_u = {imm20, rd, opcode};
    end
  endfunction

  function automatic [31:0] mk_j(
      input logic [20:0] imm21,
      input logic [4:0]  rd,
      input logic [6:0]  opcode
  );
    begin
      mk_j = {imm21[20], imm21[10:1], imm21[11], imm21[19:12], rd, opcode};
    end
  endfunction

  task automatic expected_decode(
      input  logic [31:0] instr,
      output logic        e_illegal,
      output logic        e_regwrite,
      output logic [2:0]  e_immsrc,
      output logic        e_alusrca,
      output logic        e_alusrcb,
      output logic [1:0]  e_memrw,
      output logic [2:0]  e_resultsrc,
      output logic        e_branch,
      output logic        e_jump,
      output logic        e_aluresultsrc,
      output logic [2:0]  e_aluselect,
      output logic        e_subarith
  );
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    begin
      opcode = instr[6:0];
      funct3 = instr[14:12];
      funct7 = instr[31:25];

      e_illegal      = 1'b0;
      e_regwrite     = 1'b0;
      e_immsrc       = 3'b000;
      e_alusrca      = 1'b0;
      e_alusrcb      = 1'b0;
      e_memrw        = 2'b00;
      e_resultsrc    = 3'b000;
      e_branch       = 1'b0;
      e_jump         = 1'b0;
      e_aluresultsrc = 1'b0;
      e_aluselect    = 3'b000;
      e_subarith     = 1'b0;

      case (opcode)
        7'b0000011: begin
          e_regwrite     = 1'b1;
          e_immsrc       = 3'b000;
          e_alusrca      = 1'b0;
          e_alusrcb      = 1'b1;
          e_memrw        = 2'b10;
          e_resultsrc    = 3'b001;
          e_branch       = 1'b0;
          e_jump         = 1'b0;
          e_aluresultsrc = 1'b0;
          e_aluselect    = 3'b000;
          e_subarith     = 1'b0;
          case (funct3)
            3'b000, 3'b001, 3'b010, 3'b100, 3'b101: e_illegal = 1'b0;
            default: e_illegal = 1'b1;
          endcase
        end

        7'b0010011: begin
          e_regwrite     = 1'b1;
          e_immsrc       = 3'b000;
          e_alusrca      = 1'b0;
          e_alusrcb      = 1'b1;
          e_memrw        = 2'b00;
          e_resultsrc    = 3'b000;
          e_branch       = 1'b0;
          e_jump         = 1'b0;
          e_aluresultsrc = 1'b0;
          e_aluselect    = funct3;
          e_subarith     = 1'b0;
          case (funct3)
            3'b000, 3'b100, 3'b110, 3'b111: begin
              e_illegal  = 1'b0;
              e_subarith = 1'b0;
            end
            3'b010, 3'b011: begin
              e_illegal  = 1'b0;
              e_subarith = 1'b1;
            end
            3'b001: begin
              if (funct7 == 7'b0000000) begin
                e_illegal  = 1'b0;
                e_subarith = 1'b0;
              end else begin
                e_illegal = 1'b1;
              end
            end
            3'b101: begin
              if (funct7 == 7'b0000000) begin
                e_illegal  = 1'b0;
                e_subarith = 1'b0;
              end else if (funct7 == 7'b0100000) begin
                e_illegal  = 1'b0;
                e_subarith = 1'b1;
              end else begin
                e_illegal = 1'b1;
              end
            end
            default: e_illegal = 1'b1;
          endcase
        end

        7'b0010111: begin
          e_regwrite     = 1'b1;
          e_immsrc       = 3'b100;
          e_alusrca      = 1'b1;
          e_alusrcb      = 1'b1;
          e_memrw        = 2'b00;
          e_resultsrc    = 3'b000;
          e_branch       = 1'b0;
          e_jump         = 1'b0;
          e_aluresultsrc = 1'b0;
          e_aluselect    = 3'b000;
          e_subarith     = 1'b0;
        end

        7'b0100011: begin
          e_regwrite     = 1'b0;
          e_immsrc       = 3'b001;
          e_alusrca      = 1'b0;
          e_alusrcb      = 1'b1;
          e_memrw        = 2'b01;
          e_resultsrc    = 3'b000;
          e_branch       = 1'b0;
          e_jump         = 1'b0;
          e_aluresultsrc = 1'b0;
          e_aluselect    = 3'b000;
          e_subarith     = 1'b0;
          case (funct3)
            3'b000, 3'b001, 3'b010: e_illegal = 1'b0;
            default: e_illegal = 1'b1;
          endcase
        end

        7'b0110011: begin
          e_regwrite     = 1'b1;
          e_immsrc       = 3'b000;
          e_alusrca      = 1'b0;
          e_alusrcb      = 1'b0;
          e_memrw        = 2'b00;
          e_resultsrc    = 3'b000;
          e_branch       = 1'b0;
          e_jump         = 1'b0;
          e_aluresultsrc = 1'b0;
          e_aluselect    = funct3;
          e_subarith     = 1'b0;
          case (funct3)
            3'b000: begin
              if (funct7 == 7'b0000000) begin
                e_illegal  = 1'b0;
                e_subarith = 1'b0;
              end else if (funct7 == 7'b0100000) begin
                e_illegal  = 1'b0;
                e_subarith = 1'b1;
              end else begin
                e_illegal = 1'b1;
              end
            end
            3'b001, 3'b100, 3'b110, 3'b111: begin
              if (funct7 == 7'b0000000) begin
                e_illegal  = 1'b0;
                e_subarith = 1'b0;
              end else begin
                e_illegal = 1'b1;
              end
            end
            3'b010, 3'b011: begin
              if (funct7 == 7'b0000000) begin
                e_illegal  = 1'b0;
                e_subarith = 1'b1;
              end else begin
                e_illegal = 1'b1;
              end
            end
            3'b101: begin
              if (funct7 == 7'b0000000) begin
                e_illegal  = 1'b0;
                e_subarith = 1'b0;
              end else if (funct7 == 7'b0100000) begin
                e_illegal  = 1'b0;
                e_subarith = 1'b1;
              end else begin
                e_illegal = 1'b1;
              end
            end
            default: e_illegal = 1'b1;
          endcase
        end

        7'b0110111: begin
          e_regwrite     = 1'b1;
          e_immsrc       = 3'b100;
          e_alusrca      = 1'b0;
          e_alusrcb      = 1'b1;
          e_memrw        = 2'b00;
          e_resultsrc    = 3'b000;
          e_branch       = 1'b0;
          e_jump         = 1'b0;
          e_aluresultsrc = 1'b1;
          e_aluselect    = 3'b000;
          e_subarith     = 1'b0;
        end

        7'b1100011: begin
          e_regwrite     = 1'b0;
          e_immsrc       = 3'b010;
          e_alusrca      = 1'b1;
          e_alusrcb      = 1'b1;
          e_memrw        = 2'b00;
          e_resultsrc    = 3'b000;
          e_branch       = 1'b1;
          e_jump         = 1'b0;
          e_aluresultsrc = 1'b0;
          e_aluselect    = 3'b000;
          e_subarith     = 1'b0;
          case (funct3)
            3'b000, 3'b001, 3'b100, 3'b101, 3'b110, 3'b111: e_illegal = 1'b0;
            default: e_illegal = 1'b1;
          endcase
        end

        7'b1100111: begin
          e_regwrite     = 1'b1;
          e_immsrc       = 3'b000;
          e_alusrca      = 1'b0;
          e_alusrcb      = 1'b1;
          e_memrw        = 2'b00;
          e_resultsrc    = 3'b000;
          e_branch       = 1'b0;
          e_jump         = 1'b1;
          e_aluresultsrc = 1'b1;
          e_aluselect    = 3'b000;
          e_subarith     = 1'b0;
          if (funct3 != 3'b000) e_illegal = 1'b1;
        end

        7'b1101111: begin
          e_regwrite     = 1'b1;
          e_immsrc       = 3'b011;
          e_alusrca      = 1'b1;
          e_alusrcb      = 1'b1;
          e_memrw        = 2'b00;
          e_resultsrc    = 3'b000;
          e_branch       = 1'b0;
          e_jump         = 1'b1;
          e_aluresultsrc = 1'b1;
          e_aluselect    = 3'b000;
          e_subarith     = 1'b0;
        end

        default: begin
          e_illegal = 1'b1;
        end
      endcase

      if (e_illegal) begin
        e_regwrite = 1'b0;
        e_memrw    = 2'b00;
        e_branch   = 1'b0;
        e_jump     = 1'b0;
      end
    end
  endtask

  task automatic check_bit(
      input [8*48-1:0] label,
      input logic act,
      input logic expv
  );
    begin
      total = total + 1;
      if (act === expv) begin
        passed = passed + 1;
      end else begin
        failed = failed + 1;
        if (fail_prints < 8) begin
          $display("FAIL %0s instr=%08h actual=%b expected=%b", label, InstrD, act, expv);
          fail_prints = fail_prints + 1;
        end
      end
    end
  endtask

  task automatic check_vec2(
      input [8*48-1:0] label,
      input logic [1:0] act,
      input logic [1:0] expv
  );
    begin
      total = total + 1;
      if (act === expv) begin
        passed = passed + 1;
      end else begin
        failed = failed + 1;
        if (fail_prints < 8) begin
          $display("FAIL %0s instr=%08h actual=%b expected=%b", label, InstrD, act, expv);
          fail_prints = fail_prints + 1;
        end
      end
    end
  endtask

  task automatic check_vec3(
      input [8*48-1:0] label,
      input logic [2:0] act,
      input logic [2:0] expv
  );
    begin
      total = total + 1;
      if (act === expv) begin
        passed = passed + 1;
      end else begin
        failed = failed + 1;
        if (fail_prints < 8) begin
          $display("FAIL %0s instr=%08h actual=%b expected=%b", label, InstrD, act, expv);
          fail_prints = fail_prints + 1;
        end
      end
    end
  endtask

  task automatic run_case(
      input [8*48-1:0] name,
      input logic [31:0] instr,
      input logic check_all_outputs
  );
    logic        e_illegal;
    logic        e_regwrite;
    logic [2:0]  e_immsrc;
    logic        e_alusrca;
    logic        e_alusrcb;
    logic [1:0]  e_memrw;
    logic [2:0]  e_resultsrc;
    logic        e_branch;
    logic        e_jump;
    logic        e_aluresultsrc;
    logic [2:0]  e_aluselect;
    logic        e_subarith;
    begin
      InstrD = instr;
      #1;
      expected_decode(instr, e_illegal, e_regwrite, e_immsrc, e_alusrca, e_alusrcb,
                      e_memrw, e_resultsrc, e_branch, e_jump, e_aluresultsrc,
                      e_aluselect, e_subarith);

      check_bit("IllegalInstrD", IllegalInstrD, e_illegal);
      check_bit("RegWriteD",     RegWriteD,     e_regwrite);
      check_vec2("MemRWD",       MemRWD,        e_memrw);
      check_bit("BranchD",       BranchD,       e_branch);
      check_bit("JumpD",         JumpD,         e_jump);

      if (check_all_outputs) begin
        check_vec3("ImmSrcD",       ImmSrcD,       e_immsrc);
        check_bit("ALUSrcAD",       ALUSrcAD,      e_alusrca);
        check_bit("ALUSrcBD",       ALUSrcBD,      e_alusrcb);
        check_vec3("ResultSrcD",    ResultSrcD,    e_resultsrc);
        check_bit("ALUResultSrcD",  ALUResultSrcD, e_aluresultsrc);
        check_vec3("ALUSelectD",    ALUSelectD,    e_aluselect);
        check_bit("SubArithD",      SubArithD,     e_subarith);
      end
    end
  endtask

  integer i;
  logic [4:0] shamt5;
  logic [11:0] simm12;
  logic [19:0] uimm20;
  logic [20:0] jimm21;

  initial begin
    passed = 0;
    failed = 0;
    total = 0;
    fail_prints = 0;
    InstrD = 32'h00000013;

    /* Watchdog bounds simulation time and forces FAIL on hangs. */
    fork
      begin
        #10000;
        $display("FAIL");
        $finish;
      end
    join_none

    /* Representative sample cases from the specification. */
    run_case("sample_add",     mk_r(7'b0000000, 5'd3, 5'd2, 3'b000, 5'd1, 7'b0110011), 1'b1);
    run_case("sample_sub",     mk_r(7'b0100000, 5'd3, 5'd2, 3'b000, 5'd1, 7'b0110011), 1'b1);
    run_case("sample_lw",      mk_i(12'h000,    5'd2, 3'b010, 5'd1, 7'b0000011),       1'b1);
    run_case("sample_sw",      mk_s(12'h000,    5'd1, 5'd2, 3'b010, 7'b0100011),       1'b1);
    run_case("sample_beq",     mk_b(13'h0000,   5'd2, 5'd1, 3'b000, 7'b1100011),       1'b1);
    run_case("sample_illegal", 32'h0000007f,                                           1'b0);

    /* Loads: all legal RV32I widths and all invalid funct3 values. */
    run_case("load_lb_zero",   mk_i(12'h000, 5'd2, 3'b000, 5'd1, 7'b0000011), 1'b1);
    run_case("load_lh_neg1",   mk_i(12'hfff, 5'd3, 3'b001, 5'd4, 7'b0000011), 1'b1);
    run_case("load_lw_min",    mk_i(12'h800, 5'd5, 3'b010, 5'd6, 7'b0000011), 1'b1);
    run_case("load_lbu_max",   mk_i(12'h7ff, 5'd7, 3'b100, 5'd8, 7'b0000011), 1'b1);
    run_case("load_lhu_misc",  mk_i(12'h123, 5'd9, 3'b101, 5'd10,7'b0000011), 1'b1);
    run_case("load_illegal3",  mk_i(12'h000, 5'd2, 3'b011, 5'd1, 7'b0000011), 1'b0);
    run_case("load_illegal6",  mk_i(12'h000, 5'd2, 3'b110, 5'd1, 7'b0000011), 1'b0);
    run_case("load_illegal7",  mk_i(12'h000, 5'd2, 3'b111, 5'd1, 7'b0000011), 1'b0);

    /* Stores: legal widths plus invalid funct3 values; fragmented S-immediate coverage. */
    run_case("store_sb_zero",  mk_s(12'h000, 5'd1, 5'd2, 3'b000, 7'b0100011), 1'b1);
    run_case("store_sh_neg1",  mk_s(12'hfff, 5'd3, 5'd4, 3'b001, 7'b0100011), 1'b1);
    run_case("store_sw_frag",  mk_s(12'ha5c, 5'd5, 5'd6, 3'b010, 7'b0100011), 1'b1);
    run_case("store_illegal3", mk_s(12'h123, 5'd7, 5'd8, 3'b011, 7'b0100011), 1'b0);
    run_case("store_illegal4", mk_s(12'h123, 5'd7, 5'd8, 3'b100, 7'b0100011), 1'b0);
    run_case("store_illegal7", mk_s(12'h123, 5'd7, 5'd8, 3'b111, 7'b0100011), 1'b0);

    /* Branches: every defined RV32I branch class and both illegal branch funct3 encodings. */
    run_case("branch_beq",   mk_b(13'b0_000000_0000_0, 5'd2,  5'd1,  3'b000, 7'b1100011), 1'b1);
    run_case("branch_bne",   mk_b(13'b1_111111_1110_1, 5'd3,  5'd4,  3'b001, 7'b1100011), 1'b1);
    run_case("branch_blt",   mk_b(13'h1555,            5'd5,  5'd6,  3'b100, 7'b1100011), 1'b1);
    run_case("branch_bge",   mk_b(13'h0aa2,            5'd7,  5'd8,  3'b101, 7'b1100011), 1'b1);
    run_case("branch_bltu",  mk_b(13'h1000,            5'd9,  5'd10, 3'b110, 7'b1100011), 1'b1);
    run_case("branch_bgeu",  mk_b(13'h07fe,            5'd11, 5'd12, 3'b111, 7'b1100011), 1'b1);
    run_case("branch_bad2",  mk_b(13'h0002,            5'd1,  5'd2,  3'b010, 7'b1100011), 1'b0);
    run_case("branch_bad3",  mk_b(13'h0002,            5'd1,  5'd2,  3'b011, 7'b1100011), 1'b0);

    /* Upper-immediate classes and jumps. */
    uimm20 = 20'h00000; run_case("lui_zero",   mk_u(uimm20, 5'd1, 7'b0110111), 1'b1);
    uimm20 = 20'hfffff; run_case("lui_all1",   mk_u(uimm20, 5'd2, 7'b0110111), 1'b1);
    uimm20 = 20'h80000; run_case("auipc_hi",   mk_u(uimm20, 5'd3, 7'b0010111), 1'b1);
    uimm20 = 20'h12345; run_case("auipc_misc", mk_u(uimm20, 5'd4, 7'b0010111), 1'b1);

    run_case("jalr_ok",   mk_i(12'h004, 5'd2, 3'b000, 5'd1, 7'b1100111), 1'b1);
    run_case("jalr_bad1", mk_i(12'h004, 5'd2, 3'b001, 5'd1, 7'b1100111), 1'b0);
    run_case("jalr_bad7", mk_i(12'h004, 5'd2, 3'b111, 5'd1, 7'b1100111), 1'b0);

    jimm21 = 21'h00000;  run_case("jal_zero", mk_j(jimm21, 5'd1, 7'b1101111), 1'b1);
    jimm21 = 21'h1ffffe; run_case("jal_neg2", mk_j(jimm21, 5'd2, 7'b1101111), 1'b1);
    jimm21 = 21'h155554; run_case("jal_frag", mk_j(jimm21, 5'd3, 7'b1101111), 1'b1);

    /* R-type ALU: all operation classes, legal SUB/SRA, compare classes, and illegal funct7 combinations. */
    run_case("r_add",  mk_r(7'b0000000, 5'd3,  5'd2,  3'b000, 5'd1,  7'b0110011), 1'b1);
    run_case("r_sub",  mk_r(7'b0100000, 5'd3,  5'd2,  3'b000, 5'd1,  7'b0110011), 1'b1);
    run_case("r_sll",  mk_r(7'b0000000, 5'd4,  5'd5,  3'b001, 5'd6,  7'b0110011), 1'b1);
    run_case("r_slt",  mk_r(7'b0000000, 5'd6,  5'd7,  3'b010, 5'd8,  7'b0110011), 1'b1);
    run_case("r_sltu", mk_r(7'b0000000, 5'd8,  5'd9,  3'b011, 5'd10, 7'b0110011), 1'b1);
    run_case("r_xor",  mk_r(7'b0000000, 5'd10, 5'd11, 3'b100, 5'd12, 7'b0110011), 1'b1);
    run_case("r_srl",  mk_r(7'b0000000, 5'd12, 5'd13, 3'b101, 5'd14, 7'b0110011), 1'b1);
    run_case("r_sra",  mk_r(7'b0100000, 5'd14, 5'd15, 3'b101, 5'd16, 7'b0110011), 1'b1);
    run_case("r_or",   mk_r(7'b0000000, 5'd16, 5'd17, 3'b110, 5'd18, 7'b0110011), 1'b1);
    run_case("r_and",  mk_r(7'b0000000, 5'd18, 5'd19, 3'b111, 5'd20, 7'b0110011), 1'b1);

    run_case("r_bad_add",  mk_r(7'b1111111, 5'd3,  5'd2,  3'b000, 5'd1,  7'b0110011), 1'b0);
    run_case("r_bad_sll",  mk_r(7'b0100000, 5'd4,  5'd5,  3'b001, 5'd6,  7'b0110011), 1'b0);
    run_case("r_bad_slt",  mk_r(7'b0100000, 5'd6,  5'd7,  3'b010, 5'd8,  7'b0110011), 1'b0);
    run_case("r_bad_sltu", mk_r(7'b0100000, 5'd8,  5'd9,  3'b011, 5'd10, 7'b0110011), 1'b0);
    run_case("r_bad_xor",  mk_r(7'b0100000, 5'd10, 5'd11, 3'b100, 5'd12, 7'b0110011), 1'b0);
    run_case("r_bad_or",   mk_r(7'b0100000, 5'd16, 5'd17, 3'b110, 5'd18, 7'b0110011), 1'b0);
    run_case("r_bad_and",  mk_r(7'b0100000, 5'd18, 5'd19, 3'b111, 5'd20, 7'b0110011), 1'b0);

    /* I-type ALU: all operation classes and strict shift-immediate legality. */
    run_case("i_addi_zero", mk_i(12'h000, 5'd1,  3'b000, 5'd2,  7'b0010011), 1'b1);
    run_case("i_addi_neg1", mk_i(12'hfff, 5'd1,  3'b000, 5'd2,  7'b0010011), 1'b1);
    run_case("i_xori",      mk_i(12'h123, 5'd3,  3'b100, 5'd4,  7'b0010011), 1'b1);
    run_case("i_ori",       mk_i(12'h800, 5'd5,  3'b110, 5'd6,  7'b0010011), 1'b1);
    run_case("i_andi",      mk_i(12'h7ff, 5'd7,  3'b111, 5'd8,  7'b0010011), 1'b1);
    run_case("i_slti",      mk_i(12'h001, 5'd9,  3'b010, 5'd10, 7'b0010011), 1'b1);
    run_case("i_sltiu",     mk_i(12'hffe, 5'd11, 3'b011, 5'd12, 7'b0010011), 1'b1);

    for (i = 0; i < 32; i = i + 1) begin
      shamt5 = i[4:0];

      simm12 = {7'b0000000, shamt5};
      run_case("i_slli", mk_i(simm12, 5'd13, 3'b001, 5'd14, 7'b0010011), 1'b1);

      simm12 = {7'b0000000, shamt5};
      run_case("i_srli", mk_i(simm12, 5'd15, 3'b101, 5'd16, 7'b0010011), 1'b1);

      simm12 = {7'b0100000, shamt5};
      run_case("i_srai", mk_i(simm12, 5'd17, 3'b101, 5'd18, 7'b0010011), 1'b1);
    end

    /* Illegal shift-immediate upper encodings. */
    run_case("i_slli_badA", mk_i({7'b0100000, 5'd1}, 5'd1, 3'b001, 5'd2, 7'b0010011), 1'b0);
    run_case("i_slli_badB", mk_i(12'hfff,              5'd1, 3'b001, 5'd2, 7'b0010011), 1'b0);
    run_case("i_slli_badC", mk_i({7'b0010000, 5'd3},  5'd1, 3'b001, 5'd2, 7'b0010011), 1'b0);
    run_case("i_srxi_bad",  mk_i({7'b1111111, 5'd4},  5'd1, 3'b101, 5'd2, 7'b0010011), 1'b0);

    /* Unsupported opcodes / extension spaces / system instructions are illegal. */
    run_case("ill_zero",   32'h00000000, 1'b0);
    run_case("ill_all1",   32'hffffffff, 1'b0);
    run_case("ill_fence",  32'h0000000f, 1'b0);
    run_case("ill_fencei", 32'h0000100f, 1'b0);
    run_case("ill_ecall",  32'h00000073, 1'b0);
    run_case("ill_ebreak", 32'h00100073, 1'b0);
    run_case("ill_csr",    32'h00111073, 1'b0);

    $display("A1_CHECKS passed=%0d failed=%0d total=%0d", passed, failed, total);
    if ((failed == 0) && (total > 0))
      $display("PASS");
    else
      $display("FAIL");
    $finish;
  end

endmodule
