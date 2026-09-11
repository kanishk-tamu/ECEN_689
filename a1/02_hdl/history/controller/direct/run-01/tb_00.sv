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

  typedef struct {
    logic        illegal;
    logic        regwrite;
    logic [2:0]  immsrc;
    logic        alusrca;
    logic        alusrcb;
    logic [1:0]  memrw;
    logic [2:0]  resultsrc;
    logic        branch;
    logic        jump;
    logic        aluresultsrc;
    logic [2:0]  aluselect;
    logic        subarith;
  } exp_t;

  task automatic check_bit(input string label, input logic act, input logic expv);
    begin
      total = total + 1;
      if (act === expv) begin
        passed = passed + 1;
      end else begin
        failed = failed + 1;
        if (fail_prints < 8) begin
          $display("FAIL %s instr=%08h actual=%b expected=%b", label, InstrD, act, expv);
          fail_prints = fail_prints + 1;
        end
      end
    end
  endtask

  task automatic check_vec2(input string label, input logic [1:0] act, input logic [1:0] expv);
    begin
      total = total + 1;
      if (act === expv) begin
        passed = passed + 1;
      end else begin
        failed = failed + 1;
        if (fail_prints < 8) begin
          $display("FAIL %s instr=%08h actual=%b expected=%b", label, InstrD, act, expv);
          fail_prints = fail_prints + 1;
        end
      end
    end
  endtask

  task automatic check_vec3(input string label, input logic [2:0] act, input logic [2:0] expv);
    begin
      total = total + 1;
      if (act === expv) begin
        passed = passed + 1;
      end else begin
        failed = failed + 1;
        if (fail_prints < 8) begin
          $display("FAIL %s instr=%08h actual=%b expected=%b", label, InstrD, act, expv);
          fail_prints = fail_prints + 1;
        end
      end
    end
  endtask

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

  function automatic exp_t decode_expected(input logic [31:0] instr);
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    exp_t e;
    begin
      opcode = instr[6:0];
      funct3 = instr[14:12];
      funct7 = instr[31:25];

      e.illegal      = 1'b0;
      e.regwrite     = 1'b0;
      e.immsrc       = 3'b000;
      e.alusrca      = 1'b0;
      e.alusrcb      = 1'b0;
      e.memrw        = 2'b00;
      e.resultsrc    = 3'b000;
      e.branch       = 1'b0;
      e.jump         = 1'b0;
      e.aluresultsrc = 1'b0;
      e.aluselect    = 3'b000;
      e.subarith     = 1'b0;

      case (opcode)
        7'b0000011: begin
          e.regwrite     = 1'b1;
          e.immsrc       = 3'b000;
          e.alusrca      = 1'b0;
          e.alusrcb      = 1'b1;
          e.memrw        = 2'b10;
          e.resultsrc    = 3'b001;
          e.branch       = 1'b0;
          e.jump         = 1'b0;
          e.aluresultsrc = 1'b0;
          e.aluselect    = 3'b000;
          e.subarith     = 1'b0;
          case (funct3)
            3'b000, 3'b001, 3'b010, 3'b100, 3'b101: e.illegal = 1'b0;
            default: e.illegal = 1'b1;
          endcase
        end

        7'b0010011: begin
          e.regwrite     = 1'b1;
          e.immsrc       = 3'b000;
          e.alusrca      = 1'b0;
          e.alusrcb      = 1'b1;
          e.memrw        = 2'b00;
          e.resultsrc    = 3'b000;
          e.branch       = 1'b0;
          e.jump         = 1'b0;
          e.aluresultsrc = 1'b0;
          e.aluselect    = funct3;
          e.subarith     = 1'b0;
          case (funct3)
            3'b000, 3'b100, 3'b110, 3'b111: begin
              e.illegal  = 1'b0;
              e.subarith = 1'b0;
            end
            3'b010, 3'b011: begin
              e.illegal  = 1'b0;
              e.subarith = 1'b1;
            end
            3'b001: begin
              if (funct7 == 7'b0000000) begin
                e.illegal  = 1'b0;
                e.subarith = 1'b0;
              end else begin
                e.illegal  = 1'b1;
              end
            end
            3'b101: begin
              if (funct7 == 7'b0000000) begin
                e.illegal  = 1'b0;
                e.subarith = 1'b0;
              end else if (funct7 == 7'b0100000) begin
                e.illegal  = 1'b0;
                e.subarith = 1'b1;
              end else begin
                e.illegal  = 1'b1;
              end
            end
            default: e.illegal = 1'b1;
          endcase
        end

        7'b0010111: begin
          e.regwrite     = 1'b1;
          e.immsrc       = 3'b100;
          e.alusrca      = 1'b1;
          e.alusrcb      = 1'b1;
          e.memrw        = 2'b00;
          e.resultsrc    = 3'b000;
          e.branch       = 1'b0;
          e.jump         = 1'b0;
          e.aluresultsrc = 1'b0;
          e.aluselect    = 3'b000;
          e.subarith     = 1'b0;
        end

        7'b0100011: begin
          e.regwrite     = 1'b0;
          e.immsrc       = 3'b001;
          e.alusrca      = 1'b0;
          e.alusrcb      = 1'b1;
          e.memrw        = 2'b01;
          e.resultsrc    = 3'b000;
          e.branch       = 1'b0;
          e.jump         = 1'b0;
          e.aluresultsrc = 1'b0;
          e.aluselect    = 3'b000;
          e.subarith     = 1'b0;
          case (funct3)
            3'b000, 3'b001, 3'b010: e.illegal = 1'b0;
            default: e.illegal = 1'b1;
          endcase
        end

        7'b0110011: begin
          e.regwrite     = 1'b1;
          e.immsrc       = 3'b000;
          e.alusrca      = 1'b0;
          e.alusrcb      = 1'b0;
          e.memrw        = 2'b00;
          e.resultsrc    = 3'b000;
          e.branch       = 1'b0;
          e.jump         = 1'b0;
          e.aluresultsrc = 1'b0;
          e.aluselect    = funct3;
          e.subarith     = 1'b0;
          case (funct3)
            3'b000: begin
              if (funct7 == 7'b0000000) begin
                e.illegal  = 1'b0;
                e.subarith = 1'b0;
              end else if (funct7 == 7'b0100000) begin
                e.illegal  = 1'b0;
                e.subarith = 1'b1;
              end else begin
                e.illegal  = 1'b1;
              end
            end
            3'b001, 3'b100, 3'b110, 3'b111: begin
              if (funct7 == 7'b0000000) begin
                e.illegal  = 1'b0;
                e.subarith = 1'b0;
              end else begin
                e.illegal  = 1'b1;
              end
            end
            3'b010, 3'b011: begin
              if (funct7 == 7'b0000000) begin
                e.illegal  = 1'b0;
                e.subarith = 1'b1;
              end else begin
                e.illegal  = 1'b1;
              end
            end
            3'b101: begin
              if (funct7 == 7'b0000000) begin
                e.illegal  = 1'b0;
                e.subarith = 1'b0;
              end else if (funct7 == 7'b0100000) begin
                e.illegal  = 1'b0;
                e.subarith = 1'b1;
              end else begin
                e.illegal  = 1'b1;
              end
            end
            default: e.illegal = 1'b1;
          endcase
        end

        7'b0110111: begin
          e.regwrite     = 1'b1;
          e.immsrc       = 3'b100;
          e.alusrca      = 1'b0;
          e.alusrcb      = 1'b1;
          e.memrw        = 2'b00;
          e.resultsrc    = 3'b000;
          e.branch       = 1'b0;
          e.jump         = 1'b0;
          e.aluresultsrc = 1'b1;
          e.aluselect    = 3'b000;
          e.subarith     = 1'b0;
        end

        7'b1100011: begin
          e.regwrite     = 1'b0;
          e.immsrc       = 3'b010;
          e.alusrca      = 1'b1;
          e.alusrcb      = 1'b1;
          e.memrw        = 2'b00;
          e.resultsrc    = 3'b000;
          e.branch       = 1'b1;
          e.jump         = 1'b0;
          e.aluresultsrc = 1'b0;
          e.aluselect    = 3'b000;
          e.subarith     = 1'b0;
          case (funct3)
            3'b000, 3'b001, 3'b100, 3'b101, 3'b110, 3'b111: e.illegal = 1'b0;
            default: e.illegal = 1'b1;
          endcase
        end

        7'b1100111: begin
          e.regwrite     = 1'b1;
          e.immsrc       = 3'b000;
          e.alusrca      = 1'b0;
          e.alusrcb      = 1'b1;
          e.memrw        = 2'b00;
          e.resultsrc    = 3'b000;
          e.branch       = 1'b0;
          e.jump         = 1'b1;
          e.aluresultsrc = 1'b1;
          e.aluselect    = 3'b000;
          e.subarith     = 1'b0;
          if (funct3 != 3'b000) e.illegal = 1'b1;
        end

        7'b1101111: begin
          e.regwrite     = 1'b1;
          e.immsrc       = 3'b011;
          e.alusrca      = 1'b1;
          e.alusrcb      = 1'b1;
          e.memrw        = 2'b00;
          e.resultsrc    = 3'b000;
          e.branch       = 1'b0;
          e.jump         = 1'b1;
          e.aluresultsrc = 1'b1;
          e.aluselect    = 3'b000;
          e.subarith     = 1'b0;
        end

        default: begin
          e.illegal = 1'b1;
        end
      endcase

      if (e.illegal) begin
        e.regwrite = 1'b0;
        e.memrw    = 2'b00;
        e.branch   = 1'b0;
        e.jump     = 1'b0;
      end

      decode_expected = e;
    end
  endfunction

  task automatic run_case(input string name, input logic [31:0] instr, input bit check_all_outputs);
    exp_t e;
    begin
      InstrD = instr;
      #1;
      e = decode_expected(instr);

      check_bit({name, ".IllegalInstrD"}, IllegalInstrD, e.illegal);
      check_bit({name, ".RegWriteD"},     RegWriteD,     e.regwrite);
      check_vec2({name, ".MemRWD"},       MemRWD,        e.memrw);
      check_bit({name, ".BranchD"},       BranchD,       e.branch);
      check_bit({name, ".JumpD"},         JumpD,         e.jump);

      if (check_all_outputs) begin
        check_vec3({name, ".ImmSrcD"},       ImmSrcD,       e.immsrc);
        check_bit({name, ".ALUSrcAD"},       ALUSrcAD,      e.alusrca);
        check_bit({name, ".ALUSrcBD"},       ALUSrcBD,      e.alusrcb);
        check_vec3({name, ".ResultSrcD"},    ResultSrcD,    e.resultsrc);
        check_bit({name, ".ALUResultSrcD"},  ALUResultSrcD, e.aluresultsrc);
        check_vec3({name, ".ALUSelectD"},    ALUSelectD,    e.aluselect);
        check_bit({name, ".SubArithD"},      SubArithD,     e.subarith);
      end
    end
  endtask

  integer i;
  logic [4:0] shamt5;
  logic [19:0] uimm20;
  logic [20:0] jimm21;
  logic [12:0] bimm13;
  logic [11:0] simm12;

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

    /* Sample usage examples from the specification. */
    run_case("sample_add",     mk_r(7'b0000000, 5'd3, 5'd2, 3'b000, 5'd1, 7'b0110011), 1'b1);
    run_case("sample_sub",     mk_r(7'b0100000, 5'd3, 5'd2, 3'b000, 5'd1, 7'b0110011), 1'b1);
    run_case("sample_lw",      mk_i(12'h000,    5'd2, 3'b010, 5'd1, 7'b0000011),       1'b1);
    run_case("sample_sw",      mk_s(12'h000,    5'd1, 5'd2, 3'b010, 7'b0100011),       1'b1);
    run_case("sample_beq",     mk_b(13'h0000,   5'd2, 5'd1, 3'b000, 7'b1100011),       1'b1);
    run_case("sample_illegal", 32'h0000007f,                                           1'b0);

    /* Load class: all legal funct3 values plus illegal ones; varied immediates including zero/all ones. */
    run_case("load_lb_zero",   mk_i(12'h000, 5'd2, 3'b000, 5'd1, 7'b0000011), 1'b1);
    run_case("load_lh_neg1",   mk_i(12'hfff, 5'd3, 3'b001, 5'd4, 7'b0000011), 1'b1);
    run_case("load_lw_min",    mk_i(12'h800, 5'd5, 3'b010, 5'd6, 7'b0000011), 1'b1);
    run_case("load_lbu_max",   mk_i(12'h7ff, 5'd7, 3'b100, 5'd8, 7'b0000011), 1'b1);
    run_case("load_lhu_misc",  mk_i(12'h123, 5'd9, 3'b101, 5'd10,7'b0000011), 1'b1);
    run_case("load_illegal_f3_011", mk_i(12'h000, 5'd2, 3'b011, 5'd1, 7'b0000011), 1'b0);
    run_case("load_illegal_f3_110", mk_i(12'h000, 5'd2, 3'b110, 5'd1, 7'b0000011), 1'b0);
    run_case("load_illegal_f3_111", mk_i(12'h000, 5'd2, 3'b111, 5'd1, 7'b0000011), 1'b0);

    /* Store class: all legal funct3 values plus illegal ones, fragmented S immediates. */
    run_case("store_sb_zero",  mk_s(12'h000, 5'd1, 5'd2, 3'b000, 7'b0100011), 1'b1);
    run_case("store_sh_neg1",  mk_s(12'hfff, 5'd3, 5'd4, 3'b001, 7'b0100011), 1'b1);
    run_case("store_sw_frag",  mk_s(12'ha5c, 5'd5, 5'd6, 3'b010, 7'b0100011), 1'b1);
    run_case("store_illegal_011", mk_s(12'h123, 5'd7, 5'd8, 3'b011, 7'b0100011), 1'b0);
    run_case("store_illegal_100", mk_s(12'h123, 5'd7, 5'd8, 3'b100, 7'b0100011), 1'b0);
    run_case("store_illegal_111", mk_s(12'h123, 5'd7, 5'd8, 3'b111, 7'b0100011), 1'b0);

    /* Branch class: all legal funct3 values, illegal funct3 values, and fragmented B immediates. */
    run_case("branch_beq",  mk_b(13'b0_000000_0000_0, 5'd2, 5'd1, 3'b000, 7'b1100011), 1'b1);
    run_case("branch_bne",  mk_b(13'b1_111111_1110_1, 5'd3, 5'd4, 3'b001, 7'b1100011), 1'b1);
    run_case("branch_blt",  mk_b(13'h1555,            5'd5, 5'd6, 3'b100, 7'b1100011), 1'b1);
    run_case("branch_bge",  mk_b(13'h0aa2,            5'd7, 5'd8, 3'b101, 7'b1100011), 1'b1);
    run_case("branch_bltu", mk_b(13'h1000,            5'd9, 5'd10,3'b110, 7'b1100011), 1'b1);
    run_case("branch_bgeu", mk_b(13'h07fe,            5'd11,5'd12,3'b111, 7'b1100011), 1'b1);
    run_case("branch_illegal_010", mk_b(13'h0002, 5'd1, 5'd2, 3'b010, 7'b1100011), 1'b0);
    run_case("branch_illegal_011", mk_b(13'h0002, 5'd1, 5'd2, 3'b011, 7'b1100011), 1'b0);

    /* Jumps and upper immediates including fragmented J immediate patterns. */
    uimm20 = 20'h00000; run_case("lui_zero",   mk_u(uimm20, 5'd1, 7'b0110111), 1'b1);
    uimm20 = 20'hfffff; run_case("lui_all1",   mk_u(uimm20, 5'd2, 7'b0110111), 1'b1);
    uimm20 = 20'h80000; run_case("auipc_hi",   mk_u(uimm20, 5'd3, 7'b0010111), 1'b1);
    uimm20 = 20'h12345; run_case("auipc_misc", mk_u(uimm20, 5'd4, 7'b0010111), 1'b1);

    run_case("jalr_legal",     mk_i(12'h004, 5'd2, 3'b000, 5'd1, 7'b1100111), 1'b1);
    run_case("jalr_illegal_001", mk_i(12'h004, 5'd2, 3'b001, 5'd1, 7'b1100111), 1'b0);
    run_case("jalr_illegal_111", mk_i(12'h004, 5'd2, 3'b111, 5'd1, 7'b1100111), 1'b0);

    jimm21 = 21'h00000; run_case("jal_zero", mk_j(jimm21, 5'd1, 7'b1101111), 1'b1);
    jimm21 = 21'h1ffffe; run_case("jal_neg2", mk_j(jimm21, 5'd2, 7'b1101111), 1'b1);
    jimm21 = 21'h155554; run_case("jal_frag", mk_j(jimm21, 5'd3, 7'b1101111), 1'b1);

    /* R-type ALU: every defined operation class and legal/illegal funct7 combinations. */
    run_case("r_add",  mk_r(7'b0000000, 5'd3, 5'd2, 3'b000, 5'd1, 7'b0110011), 1'b1);
    run_case("r_sub",  mk_r(7'b0100000, 5'd3, 5'd2, 3'b000, 5'd1, 7'b0110011), 1'b1);
    run_case("r_sll",  mk_r(7'b0000000, 5'd4, 5'd5, 3'b001, 5'd6, 7'b0110011), 1'b1);
    run_case("r_slt",  mk_r(7'b0000000, 5'd6, 5'd7, 3'b010, 5'd8, 7'b0110011), 1'b1);
    run_case("r_sltu", mk_r(7'b0000000, 5'd8, 5'd9, 3'b011, 5'd10,7'b0110011), 1'b1);
    run_case("r_xor",  mk_r(7'b0000000, 5'd10,5'd11,3'b100, 5'd12,7'b0110011), 1'b1);
    run_case("r_srl",  mk_r(7'b0000000, 5'd12,5'd13,3'b101, 5'd14,7'b0110011), 1'b1);
    run_case("r_sra",  mk_r(7'b0100000, 5'd14,5'd15,3'b101, 5'd16,7'b0110011), 1'b1);
    run_case("r_or",   mk_r(7'b0000000, 5'd16,5'd17,3'b110, 5'd18,7'b0110011), 1'b1);
    run_case("r_and",  mk_r(7'b0000000, 5'd18,5'd19,3'b111, 5'd20,7'b0110011), 1'b1);

    run_case("r_illegal_add_f7",  mk_r(7'b1111111, 5'd3, 5'd2, 3'b000, 5'd1, 7'b0110011), 1'b0);
    run_case("r_illegal_sll_f7",  mk_r(7'b0100000, 5'd4, 5'd5, 3'b001, 5'd6, 7'b0110011), 1'b0);
    run_case("r_illegal_slt_f7",  mk_r(7'b0100000, 5'd6, 5'd7, 3'b010, 5'd8, 7'b0110011), 1'b0);
    run_case("r_illegal_sltu_f7", mk_r(7'b0100000, 5'd8, 5'd9, 3'b011, 5'd10,7'b0110011), 1'b0);
    run_case("r_illegal_xor_f7",  mk_r(7'b0100000, 5'd10,5'd11,3'b100, 5'd12,7'b0110011), 1'b0);
    run_case("r_illegal_or_f7",   mk_r(7'b0100000, 5'd16,5'd17,3'b110, 5'd18,7'b0110011), 1'b0);
    run_case("r_illegal_and_f7",  mk_r(7'b0100000, 5'd18,5'd19,3'b111, 5'd20,7'b0110011), 1'b0);

    /* I-type ALU: every defined operation class, signed compare flags, and strict shift-immediate legality. */
    run_case("i_addi_zero", mk_i(12'h000, 5'd1, 3'b000, 5'd2, 7'b0010011), 1'b1);
    run_case("i_addi_neg1", mk_i(12'hfff, 5'd1, 3'b000, 5'd2, 7'b0010011), 1'b1);
    run_case("i_xori",      mk_i(12'h123, 5'd3, 3'b100, 5'd4, 7'b0010011), 1'b1);
    run_case("i_ori",       mk_i(12'h800, 5'd5, 3'b110, 5'd6, 7'b0010011), 1'b1);
    run_case("i_andi",      mk_i(12'h7ff, 5'd7, 3'b111, 5'd8, 7'b0010011), 1'b1);
    run_case("i_slti",      mk_i(12'h001, 5'd9, 3'b010, 5'd10,7'b0010011), 1'b1);
    run_case("i_sltiu",     mk_i(12'hffe, 5'd11,3'b011, 5'd12,7'b0010011), 1'b1);

    for (i = 0; i < 32; i = i + 1) begin
      shamt5 = i[4:0];
      simm12 = {7'b0000000, shamt5};
      run_case("i_slli_masked", mk_i(simm12, 5'd13, 3'b001, 5'd14, 7'b0010011), 1'b1);

      simm12 = {7'b0000000, shamt5};
      run_case("i_srli_masked", mk_i(simm12, 5'd15, 3'b101, 5'd16, 7'b0010011), 1'b1);

      simm12 = {7'b0100000, shamt5};
      run_case("i_srai_masked", mk_i(simm12, 5'd17, 3'b101, 5'd18, 7'b0010011), 1'b1);
    end

    run_case("i_slli_illegal_f7", mk_i({7'b0100000,5'd1}, 5'd1, 3'b001, 5'd2, 7'b0010011), 1'b0);
    run_case("i_slli_illegal_all1", mk_i(12'hfff, 5'd1, 3'b001, 5'd2, 7'b0010011), 1'b0);
    run_case("i_shift_illegal_mid", mk_i({7'b0010000,5'd3}, 5'd1, 3'b001, 5'd2, 7'b0010011), 1'b0);
    run_case("i_srxi_illegal_f7", mk_i({7'b1111111,5'd4}, 5'd1, 3'b101, 5'd2, 7'b0010011), 1'b0);

    /* Illegal/unsupported opcodes and extension-space encodings. */
    run_case("illegal_opcode_zero", 32'h00000000, 1'b0);
    run_case("illegal_opcode_all1", 32'hffffffff, 1'b0);
    run_case("illegal_fence",       32'h0000000f, 1'b0);
    run_case("illegal_fence_i",     32'h0000100f, 1'b0);
    run_case("illegal_ecall",       32'h00000073, 1'b0);
    run_case("illegal_ebreak",      32'h00100073, 1'b0);
    run_case("illegal_csr",         32'h00111073, 1'b0);

    $display("A1_CHECKS passed=%0d failed=%0d total=%0d", passed, failed, total);
    if ((failed == 0) && (total > 0))
      $display("PASS");
    else
      $display("FAIL");
    $finish;
  end

endmodule
