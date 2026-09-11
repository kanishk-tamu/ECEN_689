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

  integer passed;
  integer failed;
  integer total;
  integer fail_prints;

  typedef struct {
    logic legal;
    logic RegWriteD;
    logic [2:0] ImmSrcD;
    logic ALUSrcAD;
    logic ALUSrcBD;
    logic [1:0] MemRWD;
    logic [2:0] ResultSrcD;
    logic BranchD;
    logic JumpD;
    logic ALUResultSrcD;
    logic [2:0] ALUSelectD;
    logic SubArithD;
    logic IllegalInstrD;
  } exp_t;

  function automatic [31:0] mk_rtype(
    input logic [6:0] funct7,
    input logic [4:0] rs2,
    input logic [4:0] rs1,
    input logic [2:0] funct3,
    input logic [4:0] rd,
    input logic [6:0] opcode
  );
    mk_rtype = {funct7, rs2, rs1, funct3, rd, opcode};
  endfunction

  function automatic [31:0] mk_itype(
    input logic [11:0] imm12,
    input logic [4:0] rs1,
    input logic [2:0] funct3,
    input logic [4:0] rd,
    input logic [6:0] opcode
  );
    mk_itype = {imm12, rs1, funct3, rd, opcode};
  endfunction

  function automatic [31:0] mk_stype(
    input logic [11:0] imm12,
    input logic [4:0] rs2,
    input logic [4:0] rs1,
    input logic [2:0] funct3,
    input logic [6:0] opcode
  );
    mk_stype = {imm12[11:5], rs2, rs1, funct3, imm12[4:0], opcode};
  endfunction

  function automatic [31:0] mk_btype(
    input logic [12:0] imm13,
    input logic [4:0] rs2,
    input logic [4:0] rs1,
    input logic [2:0] funct3,
    input logic [6:0] opcode
  );
    mk_btype = {imm13[12], imm13[10:5], rs2, rs1, funct3, imm13[4:1], imm13[11], opcode};
  endfunction

  function automatic [31:0] mk_utype(
    input logic [19:0] imm20,
    input logic [4:0] rd,
    input logic [6:0] opcode
  );
    mk_utype = {imm20, rd, opcode};
  endfunction

  function automatic [31:0] mk_jtype(
    input logic [20:0] imm21,
    input logic [4:0] rd,
    input logic [6:0] opcode
  );
    mk_jtype = {imm21[20], imm21[10:1], imm21[11], imm21[19:12], rd, opcode};
  endfunction

  function automatic exp_t decode_expected(input logic [31:0] instr);
    exp_t e;
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    opcode = instr[6:0];
    funct3 = instr[14:12];
    funct7 = instr[31:25];

    e.legal         = 1'b0;
    e.RegWriteD     = 1'b0;
    e.ImmSrcD       = 3'b000;
    e.ALUSrcAD      = 1'b0;
    e.ALUSrcBD      = 1'b0;
    e.MemRWD        = 2'b00;
    e.ResultSrcD    = 3'b000;
    e.BranchD       = 1'b0;
    e.JumpD         = 1'b0;
    e.ALUResultSrcD = 1'b0;
    e.ALUSelectD    = 3'b000;
    e.SubArithD     = 1'b0;
    e.IllegalInstrD = 1'b1;

    case (opcode)
      7'b0000011: begin
        if ((funct3 == 3'b000) || (funct3 == 3'b001) || (funct3 == 3'b010) ||
            (funct3 == 3'b100) || (funct3 == 3'b101)) begin
          e.legal         = 1'b1;
          e.RegWriteD     = 1'b1;
          e.ImmSrcD       = 3'b000;
          e.ALUSrcAD      = 1'b0;
          e.ALUSrcBD      = 1'b1;
          e.MemRWD        = 2'b10;
          e.ResultSrcD    = 3'b001;
          e.BranchD       = 1'b0;
          e.JumpD         = 1'b0;
          e.ALUResultSrcD = 1'b0;
          e.ALUSelectD    = 3'b000;
          e.SubArithD     = 1'b0;
          e.IllegalInstrD = 1'b0;
        end
      end

      7'b0010011: begin
        case (funct3)
          3'b000, 3'b010, 3'b011, 3'b100, 3'b110, 3'b111: begin
            e.legal         = 1'b1;
            e.RegWriteD     = 1'b1;
            e.ImmSrcD       = 3'b000;
            e.ALUSrcAD      = 1'b0;
            e.ALUSrcBD      = 1'b1;
            e.MemRWD        = 2'b00;
            e.ResultSrcD    = 3'b000;
            e.BranchD       = 1'b0;
            e.JumpD         = 1'b0;
            e.ALUResultSrcD = 1'b0;
            e.ALUSelectD    = funct3;
            e.SubArithD     = ((funct3 == 3'b010) || (funct3 == 3'b011)) ? 1'b1 : 1'b0;
            e.IllegalInstrD = 1'b0;
          end
          3'b001: begin
            if (funct7 == 7'b0000000) begin
              e.legal         = 1'b1;
              e.RegWriteD     = 1'b1;
              e.ImmSrcD       = 3'b000;
              e.ALUSrcAD      = 1'b0;
              e.ALUSrcBD      = 1'b1;
              e.MemRWD        = 2'b00;
              e.ResultSrcD    = 3'b000;
              e.BranchD       = 1'b0;
              e.JumpD         = 1'b0;
              e.ALUResultSrcD = 1'b0;
              e.ALUSelectD    = 3'b001;
              e.SubArithD     = 1'b0;
              e.IllegalInstrD = 1'b0;
            end
          end
          3'b101: begin
            if (funct7 == 7'b0000000) begin
              e.legal         = 1'b1;
              e.RegWriteD     = 1'b1;
              e.ImmSrcD       = 3'b000;
              e.ALUSrcAD      = 1'b0;
              e.ALUSrcBD      = 1'b1;
              e.MemRWD        = 2'b00;
              e.ResultSrcD    = 3'b000;
              e.BranchD       = 1'b0;
              e.JumpD         = 1'b0;
              e.ALUResultSrcD = 1'b0;
              e.ALUSelectD    = 3'b101;
              e.SubArithD     = 1'b0;
              e.IllegalInstrD = 1'b0;
            end else if (funct7 == 7'b0100000) begin
              e.legal         = 1'b1;
              e.RegWriteD     = 1'b1;
              e.ImmSrcD       = 3'b000;
              e.ALUSrcAD      = 1'b0;
              e.ALUSrcBD      = 1'b1;
              e.MemRWD        = 2'b00;
              e.ResultSrcD    = 3'b000;
              e.BranchD       = 1'b0;
              e.JumpD         = 1'b0;
              e.ALUResultSrcD = 1'b0;
              e.ALUSelectD    = 3'b101;
              e.SubArithD     = 1'b1;
              e.IllegalInstrD = 1'b0;
            end
          end
          default: begin
          end
        endcase
      end

      7'b0010111: begin
        e.legal         = 1'b1;
        e.RegWriteD     = 1'b1;
        e.ImmSrcD       = 3'b100;
        e.ALUSrcAD      = 1'b1;
        e.ALUSrcBD      = 1'b1;
        e.MemRWD        = 2'b00;
        e.ResultSrcD    = 3'b000;
        e.BranchD       = 1'b0;
        e.JumpD         = 1'b0;
        e.ALUResultSrcD = 1'b0;
        e.ALUSelectD    = 3'b000;
        e.SubArithD     = 1'b0;
        e.IllegalInstrD = 1'b0;
      end

      7'b0100011: begin
        if ((funct3 == 3'b000) || (funct3 == 3'b001) || (funct3 == 3'b010)) begin
          e.legal         = 1'b1;
          e.RegWriteD     = 1'b0;
          e.ImmSrcD       = 3'b001;
          e.ALUSrcAD      = 1'b0;
          e.ALUSrcBD      = 1'b1;
          e.MemRWD        = 2'b01;
          e.ResultSrcD    = 3'b000;
          e.BranchD       = 1'b0;
          e.JumpD         = 1'b0;
          e.ALUResultSrcD = 1'b0;
          e.ALUSelectD    = 3'b000;
          e.SubArithD     = 1'b0;
          e.IllegalInstrD = 1'b0;
        end
      end

      7'b0110011: begin
        case (funct3)
          3'b000: begin
            if (funct7 == 7'b0000000) begin
              e.legal         = 1'b1;
              e.RegWriteD     = 1'b1;
              e.ImmSrcD       = 3'b000;
              e.ALUSrcAD      = 1'b0;
              e.ALUSrcBD      = 1'b0;
              e.MemRWD        = 2'b00;
              e.ResultSrcD    = 3'b000;
              e.BranchD       = 1'b0;
              e.JumpD         = 1'b0;
              e.ALUResultSrcD = 1'b0;
              e.ALUSelectD    = 3'b000;
              e.SubArithD     = 1'b0;
              e.IllegalInstrD = 1'b0;
            end else if (funct7 == 7'b0100000) begin
              e.legal         = 1'b1;
              e.RegWriteD     = 1'b1;
              e.ImmSrcD       = 3'b000;
              e.ALUSrcAD      = 1'b0;
              e.ALUSrcBD      = 1'b0;
              e.MemRWD        = 2'b00;
              e.ResultSrcD    = 3'b000;
              e.BranchD       = 1'b0;
              e.JumpD         = 1'b0;
              e.ALUResultSrcD = 1'b0;
              e.ALUSelectD    = 3'b000;
              e.SubArithD     = 1'b1;
              e.IllegalInstrD = 1'b0;
            end
          end
          3'b001, 3'b010, 3'b011, 3'b100, 3'b110, 3'b111: begin
            if (funct7 == 7'b0000000) begin
              e.legal         = 1'b1;
              e.RegWriteD     = 1'b1;
              e.ImmSrcD       = 3'b000;
              e.ALUSrcAD      = 1'b0;
              e.ALUSrcBD      = 1'b0;
              e.MemRWD        = 2'b00;
              e.ResultSrcD    = 3'b000;
              e.BranchD       = 1'b0;
              e.JumpD         = 1'b0;
              e.ALUResultSrcD = 1'b0;
              e.ALUSelectD    = funct3;
              e.SubArithD     = ((funct3 == 3'b010) || (funct3 == 3'b011)) ? 1'b1 : 1'b0;
              e.IllegalInstrD = 1'b0;
            end
          end
          3'b101: begin
            if (funct7 == 7'b0000000) begin
              e.legal         = 1'b1;
              e.RegWriteD     = 1'b1;
              e.ImmSrcD       = 3'b000;
              e.ALUSrcAD      = 1'b0;
              e.ALUSrcBD      = 1'b0;
              e.MemRWD        = 2'b00;
              e.ResultSrcD    = 3'b000;
              e.BranchD       = 1'b0;
              e.JumpD         = 1'b0;
              e.ALUResultSrcD = 1'b0;
              e.ALUSelectD    = 3'b101;
              e.SubArithD     = 1'b0;
              e.IllegalInstrD = 1'b0;
            end else if (funct7 == 7'b0100000) begin
              e.legal         = 1'b1;
              e.RegWriteD     = 1'b1;
              e.ImmSrcD       = 3'b000;
              e.ALUSrcAD      = 1'b0;
              e.ALUSrcBD      = 1'b0;
              e.MemRWD        = 2'b00;
              e.ResultSrcD    = 3'b000;
              e.BranchD       = 1'b0;
              e.JumpD         = 1'b0;
              e.ALUResultSrcD = 1'b0;
              e.ALUSelectD    = 3'b101;
              e.SubArithD     = 1'b1;
              e.IllegalInstrD = 1'b0;
            end
          end
          default: begin
          end
        endcase
      end

      7'b0110111: begin
        e.legal         = 1'b1;
        e.RegWriteD     = 1'b1;
        e.ImmSrcD       = 3'b100;
        e.ALUSrcAD      = 1'b0;
        e.ALUSrcBD      = 1'b1;
        e.MemRWD        = 2'b00;
        e.ResultSrcD    = 3'b000;
        e.BranchD       = 1'b0;
        e.JumpD         = 1'b0;
        e.ALUResultSrcD = 1'b1;
        e.ALUSelectD    = 3'b000;
        e.SubArithD     = 1'b0;
        e.IllegalInstrD = 1'b0;
      end

      7'b1100011: begin
        if ((funct3 == 3'b000) || (funct3 == 3'b001) || (funct3 == 3'b100) ||
            (funct3 == 3'b101) || (funct3 == 3'b110) || (funct3 == 3'b111)) begin
          e.legal         = 1'b1;
          e.RegWriteD     = 1'b0;
          e.ImmSrcD       = 3'b010;
          e.ALUSrcAD      = 1'b1;
          e.ALUSrcBD      = 1'b1;
          e.MemRWD        = 2'b00;
          e.ResultSrcD    = 3'b000;
          e.BranchD       = 1'b1;
          e.JumpD         = 1'b0;
          e.ALUResultSrcD = 1'b0;
          e.ALUSelectD    = 3'b000;
          e.SubArithD     = 1'b0;
          e.IllegalInstrD = 1'b0;
        end
      end

      7'b1100111: begin
        if (funct3 == 3'b000) begin
          e.legal         = 1'b1;
          e.RegWriteD     = 1'b1;
          e.ImmSrcD       = 3'b000;
          e.ALUSrcAD      = 1'b0;
          e.ALUSrcBD      = 1'b1;
          e.MemRWD        = 2'b00;
          e.ResultSrcD    = 3'b000;
          e.BranchD       = 1'b0;
          e.JumpD         = 1'b1;
          e.ALUResultSrcD = 1'b1;
          e.ALUSelectD    = 3'b000;
          e.SubArithD     = 1'b0;
          e.IllegalInstrD = 1'b0;
        end
      end

      7'b1101111: begin
        e.legal         = 1'b1;
        e.RegWriteD     = 1'b1;
        e.ImmSrcD       = 3'b011;
        e.ALUSrcAD      = 1'b1;
        e.ALUSrcBD      = 1'b1;
        e.MemRWD        = 2'b00;
        e.ResultSrcD    = 3'b000;
        e.BranchD       = 1'b0;
        e.JumpD         = 1'b1;
        e.ALUResultSrcD = 1'b1;
        e.ALUSelectD    = 3'b000;
        e.SubArithD     = 1'b0;
        e.IllegalInstrD = 1'b0;
      end

      default: begin
      end
    endcase

    if (!e.legal) begin
      e.RegWriteD     = 1'b0;
      e.MemRWD        = 2'b00;
      e.BranchD       = 1'b0;
      e.JumpD         = 1'b0;
      e.IllegalInstrD = 1'b1;
    end

    decode_expected = e;
  endfunction

  task automatic note_fail_bit(
    input [255:0] label,
    input logic [31:0] instr,
    input logic actual,
    input logic expected
  );
    begin
      if (fail_prints < 8) begin
        $display("FAIL %0s instr=%08h actual=%b expected=%b", label, instr, actual, expected);
        fail_prints = fail_prints + 1;
      end
    end
  endtask

  task automatic note_fail_vec2(
    input [255:0] label,
    input logic [31:0] instr,
    input logic [1:0] actual,
    input logic [1:0] expected
  );
    begin
      if (fail_prints < 8) begin
        $display("FAIL %0s instr=%08h actual=%b expected=%b", label, instr, actual, expected);
        fail_prints = fail_prints + 1;
      end
    end
  endtask

  task automatic note_fail_vec3(
    input [255:0] label,
    input logic [31:0] instr,
    input logic [2:0] actual,
    input logic [2:0] expected
  );
    begin
      if (fail_prints < 8) begin
        $display("FAIL %0s instr=%08h actual=%b expected=%b", label, instr, actual, expected);
        fail_prints = fail_prints + 1;
      end
    end
  endtask

  task automatic check_bit(
    input [255:0] label,
    input logic [31:0] instr,
    input logic actual,
    input logic expected
  );
    begin
      total = total + 1;
      if (actual === expected) begin
        passed = passed + 1;
      end else begin
        failed = failed + 1;
        note_fail_bit(label, instr, actual, expected);
      end
    end
  endtask

  task automatic check_vec2(
    input [255:0] label,
    input logic [31:0] instr,
    input logic [1:0] actual,
    input logic [1:0] expected
  );
    begin
      total = total + 1;
      if (actual === expected) begin
        passed = passed + 1;
      end else begin
        failed = failed + 1;
        note_fail_vec2(label, instr, actual, expected);
      end
    end
  endtask

  task automatic check_vec3(
    input [255:0] label,
    input logic [31:0] instr,
    input logic [2:0] actual,
    input logic [2:0] expected
  );
    begin
      total = total + 1;
      if (actual === expected) begin
        passed = passed + 1;
      end else begin
        failed = failed + 1;
        note_fail_vec3(label, instr, actual, expected);
      end
    end
  endtask

  task automatic apply_and_check(
    input [255:0] name,
    input logic [31:0] instr
  );
    exp_t e;
    begin
      // Coverage intent:
      // - all legal controller instruction classes in the specification
      // - all ALUSelect classes via I-type and R-type encodings
      // - instructor sample cases
      // - strict illegal decoding for unsupported funct3/funct7/opcode cases
      // - fragmented immediate layouts for B/J/S/U encodings
      // - zero/all-ones and shift boundary encodings
      InstrD = instr;
      #1;
      e = decode_expected(instr);

      if (e.legal) begin
        check_bit ("RegWriteD",     instr, RegWriteD,     e.RegWriteD);
        check_vec3("ImmSrcD",       instr, ImmSrcD,       e.ImmSrcD);
        check_bit ("ALUSrcAD",      instr, ALUSrcAD,      e.ALUSrcAD);
        check_bit ("ALUSrcBD",      instr, ALUSrcBD,      e.ALUSrcBD);
        check_vec2("MemRWD",        instr, MemRWD,        e.MemRWD);
        check_vec3("ResultSrcD",    instr, ResultSrcD,    e.ResultSrcD);
        check_bit ("BranchD",       instr, BranchD,       e.BranchD);
        check_bit ("JumpD",         instr, JumpD,         e.JumpD);
        check_bit ("ALUResultSrcD", instr, ALUResultSrcD, e.ALUResultSrcD);
        check_vec3("ALUSelectD",    instr, ALUSelectD,    e.ALUSelectD);
        check_bit ("SubArithD",     instr, SubArithD,     e.SubArithD);
        check_bit ("IllegalInstrD", instr, IllegalInstrD, e.IllegalInstrD);
      end else begin
        check_bit ("IllegalInstrD", instr, IllegalInstrD, 1'b1);
        check_bit ("RegWriteD",     instr, RegWriteD,     1'b0);
        check_vec2("MemRWD",        instr, MemRWD,        2'b00);
        check_bit ("BranchD",       instr, BranchD,       1'b0);
        check_bit ("JumpD",         instr, JumpD,         1'b0);
      end
    end
  endtask

  integer i;
  logic [4:0] shamt5;
  logic [31:0] instr_tmp;
  logic [4:0] rd_tmp;
  logic [4:0] rs1_tmp;
  logic [4:0] rs2_tmp;

  initial begin
    #100000;
    $display("FAIL");
    $finish;
  end

  initial begin
    passed = 0;
    failed = 0;
    total = 0;
    fail_prints = 0;
    InstrD = 32'h00000000;

    // Sample cases from the specification.
    apply_and_check("sample add",          mk_rtype(7'b0000000, 5'd3, 5'd2, 3'b000, 5'd1, 7'b0110011));
    apply_and_check("sample sub",          mk_rtype(7'b0100000, 5'd3, 5'd2, 3'b000, 5'd1, 7'b0110011));
    apply_and_check("sample lw",           mk_itype(12'h000, 5'd2, 3'b010, 5'd1, 7'b0000011));
    apply_and_check("sample sw",           mk_stype(12'h000, 5'd1, 5'd2, 3'b010, 7'b0100011));
    apply_and_check("sample beq",          mk_btype(13'h0000, 5'd2, 5'd1, 3'b000, 7'b1100011));
    apply_and_check("sample illegal",      32'h0000007f);

    // Loads: all legal funct3 and illegal funct3.
    apply_and_check("lb",                  mk_itype(12'h000, 5'd2, 3'b000, 5'd1, 7'b0000011));
    apply_and_check("lh",                  mk_itype(12'h7ff, 5'd3, 3'b001, 5'd4, 7'b0000011));
    apply_and_check("lw",                  mk_itype(12'h800, 5'd5, 3'b010, 5'd6, 7'b0000011));
    apply_and_check("lbu",                 mk_itype(12'h123, 5'd7, 3'b100, 5'd8, 7'b0000011));
    apply_and_check("lhu",                 mk_itype(12'hfff, 5'd9, 3'b101, 5'd10, 7'b0000011));
    apply_and_check("illegal load 011",    mk_itype(12'h111, 5'd1, 3'b011, 5'd2, 7'b0000011));
    apply_and_check("illegal load 110",    mk_itype(12'h222, 5'd1, 3'b110, 5'd2, 7'b0000011));
    apply_and_check("illegal load 111",    mk_itype(12'h333, 5'd1, 3'b111, 5'd2, 7'b0000011));

    // I-type ALU: all operation classes and illegal shift-immediate encodings.
    apply_and_check("addi zero",           mk_itype(12'h000, 5'd1, 3'b000, 5'd2, 7'b0010011));
    apply_and_check("addi all ones",       mk_itype(12'hfff, 5'd1, 3'b000, 5'd2, 7'b0010011));
    apply_and_check("slti",                mk_itype(12'h800, 5'd3, 3'b010, 5'd4, 7'b0010011));
    apply_and_check("sltiu",               mk_itype(12'h7ff, 5'd5, 3'b011, 5'd6, 7'b0010011));
    apply_and_check("xori",                mk_itype(12'h555, 5'd7, 3'b100, 5'd8, 7'b0010011));
    apply_and_check("ori",                 mk_itype(12'haaa, 5'd9, 3'b110, 5'd10, 7'b0010011));
    apply_and_check("andi",                mk_itype(12'h001, 5'd11, 3'b111, 5'd12, 7'b0010011));

    shamt5 = 5'd0;
    instr_tmp = mk_itype({7'b0000000, shamt5}, 5'd1, 3'b001, 5'd2, 7'b0010011);
    apply_and_check("slli shamt0",         instr_tmp);
    shamt5 = 5'd31;
    instr_tmp = mk_itype({7'b0000000, shamt5}, 5'd1, 3'b001, 5'd2, 7'b0010011);
    apply_and_check("slli shamt31",        instr_tmp);

    shamt5 = 5'd0;
    instr_tmp = mk_itype({7'b0000000, shamt5}, 5'd1, 3'b101, 5'd2, 7'b0010011);
    apply_and_check("srli shamt0",         instr_tmp);
    shamt5 = 5'd31;
    instr_tmp = mk_itype({7'b0000000, shamt5}, 5'd1, 3'b101, 5'd2, 7'b0010011);
    apply_and_check("srli shamt31",        instr_tmp);

    shamt5 = 5'd0;
    instr_tmp = mk_itype({7'b0100000, shamt5}, 5'd1, 3'b101, 5'd2, 7'b0010011);
    apply_and_check("srai shamt0",         instr_tmp);
    shamt5 = 5'd31;
    instr_tmp = mk_itype({7'b0100000, shamt5}, 5'd1, 3'b101, 5'd2, 7'b0010011);
    apply_and_check("srai shamt31",        instr_tmp);

    shamt5 = 5'd1;
    instr_tmp = mk_itype({7'b0100000, shamt5}, 5'd1, 3'b001, 5'd2, 7'b0010011);
    apply_and_check("illegal slli funct7", instr_tmp);
    shamt5 = 5'd2;
    instr_tmp = mk_itype({7'b0010000, shamt5}, 5'd1, 3'b101, 5'd2, 7'b0010011);
    apply_and_check("illegal shifti",      instr_tmp);

    // U-type forms.
    apply_and_check("auipc zero",          mk_utype(20'h00000, 5'd1, 7'b0010111));
    apply_and_check("auipc all ones",      mk_utype(20'hfffff, 5'd31, 7'b0010111));
    apply_and_check("lui zero",            mk_utype(20'h00000, 5'd2, 7'b0110111));
    apply_and_check("lui all ones",        mk_utype(20'hfffff, 5'd30, 7'b0110111));

    // Stores.
    apply_and_check("sb",                  mk_stype(12'h000, 5'd1, 5'd2, 3'b000, 7'b0100011));
    apply_and_check("sh",                  mk_stype(12'h7ff, 5'd3, 5'd4, 3'b001, 7'b0100011));
    apply_and_check("sw",                  mk_stype(12'h800, 5'd5, 5'd6, 3'b010, 7'b0100011));
    apply_and_check("illegal store 011",   mk_stype(12'h123, 5'd1, 5'd2, 3'b011, 7'b0100011));
    apply_and_check("illegal store 100",   mk_stype(12'h456, 5'd1, 5'd2, 3'b100, 7'b0100011));
    apply_and_check("illegal store 111",   mk_stype(12'h789, 5'd1, 5'd2, 3'b111, 7'b0100011));

    // R-type ALU classes and strict funct7 legality.
    apply_and_check("add",                 mk_rtype(7'b0000000, 5'd3, 5'd2, 3'b000, 5'd1, 7'b0110011));
    apply_and_check("sub",                 mk_rtype(7'b0100000, 5'd3, 5'd2, 3'b000, 5'd1, 7'b0110011));
    apply_and_check("sll",                 mk_rtype(7'b0000000, 5'd3, 5'd2, 3'b001, 5'd1, 7'b0110011));
    apply_and_check("slt",                 mk_rtype(7'b0000000, 5'd3, 5'd2, 3'b010, 5'd1, 7'b0110011));
    apply_and_check("sltu",                mk_rtype(7'b0000000, 5'd3, 5'd2, 3'b011, 5'd1, 7'b0110011));
    apply_and_check("xor",                 mk_rtype(7'b0000000, 5'd3, 5'd2, 3'b100, 5'd1, 7'b0110011));
    apply_and_check("srl",                 mk_rtype(7'b0000000, 5'd3, 5'd2, 3'b101, 5'd1, 7'b0110011));
    apply_and_check("sra",                 mk_rtype(7'b0100000, 5'd3, 5'd2, 3'b101, 5'd1, 7'b0110011));
    apply_and_check("or",                  mk_rtype(7'b0000000, 5'd3, 5'd2, 3'b110, 5'd1, 7'b0110011));
    apply_and_check("and",                 mk_rtype(7'b0000000, 5'd3, 5'd2, 3'b111, 5'd1, 7'b0110011));

    apply_and_check("illegal r add",       mk_rtype(7'b0000001, 5'd3, 5'd2, 3'b000, 5'd1, 7'b0110011));
    apply_and_check("illegal r sll",       mk_rtype(7'b0100000, 5'd3, 5'd2, 3'b001, 5'd1, 7'b0110011));
    apply_and_check("illegal r slt",       mk_rtype(7'b0100000, 