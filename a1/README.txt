ECEN 689 Assignment 1 | Fall 2026 | UIN 137008874

01_code/    All custom workflow code and three prompt styles in student_code/lab1.py.
            The provided helpers, specifications and sample suites are unchanged.
02_hdl/     history/ contains every generated HDL version by block/style/run.
            final/ contains alu.sv, regfile.sv, extend.sv, controller.sv and their TBs.
03_records/ Every exact request, full response, returned model ID, usage, settings,
            score and simulation log; also final selections and verification logs.
04_report/  Assignment report based on the fresh single-file experiment.

SETUP
cd 01_code
python -m pip install -r requirements.txt
cp env.example .env
# Add your TAMU or OpenAI key to .env locally. No keys are included in this ZIP.
# Install Icarus Verilog and ensure iverilog and vvp are on PATH.
# This workflow uses POSIX process groups/fork; run on macOS or Linux.

GENERATE ONE RUN PER BLOCK (from 01_code; choose unused result directories)
python student_code/lab1.py --spec specs/alu.yaml --out-dir results/alu --provider tamu
python student_code/lab1.py --spec specs/regfile.yaml --out-dir results/regfile --provider tamu
python student_code/lab1.py --spec specs/extend.yaml --out-dir results/extend --provider tamu
python student_code/lab1.py --spec specs/controller.yaml --out-dir results/controller --provider tamu
# Replace tamu with openai if using that provider. Default style: constraints.

RUN THE 24-REQUEST-START EXPERIMENT (bash, from 01_code)
for block in alu regfile extend controller; do
  for style in direct constraints template; do
    for run in 1 2; do
      A1_STYLE="$style" python student_code/lab1.py --spec "specs/$block.yaml" --out-dir "results/experiment/$block/$style/run-$run" --provider tamu
    done
  done
done
# Failed bounded runs exit nonzero; continue all iterations and retain the records.
# Each run uses 2 initial calls plus at most 3 RTL and 2 TB repairs.
# Only the supplied samples drive RTL repair; TB refinement is separate.

VERIFY THE SUBMITTED FINAL RTL (from 01_code; no API calls)
bash module_packages/alu/scripts/run_alu.sh ../02_hdl/final/alu.sv
bash module_packages/regfile/scripts/run_regfile.sh ../02_hdl/final/regfile.sv
bash module_packages/extend/scripts/run_extend.sh ../02_hdl/final/extend.sv
bash module_packages/controller/scripts/run_controller.sh ../02_hdl/final/controller.sv

VERIFY THE SUBMITTED TBS (from 01_code; create runner-compatible result paths)
for block in alu regfile extend controller; do
  mkdir -p "results/$block"
  cp "../02_hdl/final/$block.sv" "results/$block/final_rtl.sv"
  cp "../02_hdl/final/${block}_tb.sv" "results/$block/${block}_tb.sv"
  bash run_generated_tb.sh "$block"
done
# Use an empty results folder for this verification, separate from new experiments.

RECORD PATHS
03_records/experiment/<block>/<style>/<run>/manifest.json lists attempt filenames.
Those .sv files are in 02_hdl/history/<block>/<style>/<run>/ with the same names.
Request, response, score and log files retain their corresponding attempt prefixes.
Absolute paths in historical logs are provenance, not dependencies.
All 24 runs were newly executed using this exact lab1.py; no old benchmark was
relabelled. Only marked Phase A/B/C regions were edited. There are no new workflow
helper files, MCP connectors or optional agent modules in this submission.
