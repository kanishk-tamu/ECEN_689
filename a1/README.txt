ECEN 689 Assignment 1 | UIN 137008874

CONTENTS
01_code/    student_code/lab1.py contains all workflow code. prompt_templates/
            lists each tested style, the system prompt and TB template. Provided
            helpers, specs, sample suites and provider package are unchanged.
02_hdl/     history/<block>/<style>/<run>/ contains all generated HDL versions.
            final/ contains the four named RTL files and four final testbenches.
03_records/ Exact requests, full responses, model/settings/token counts and logs.
            run_index.csv links every measured attempt to its HDL and records.
04_report/  Latest PDF report, including the public GitHub repository link.

SETUP AND GENERATION (bash; from 01_code; macOS or Linux)
cd 01_code
python -m pip install -r requirements.txt
# Configure your own TAMUS_AI_CHAT_API_KEY or OPENAI_API_KEY locally.
# Icarus Verilog and vvp must be installed and on PATH.
python student_code/lab1.py --spec specs/alu.yaml --out-dir results/alu --provider tamu
python student_code/lab1.py --spec specs/regfile.yaml --out-dir results/regfile --provider tamu
python student_code/lab1.py --spec specs/extend.yaml --out-dir results/extend --provider tamu
python student_code/lab1.py --spec specs/controller.yaml --out-dir results/controller --provider tamu
# Replace tamu with openai when using that provider. Use unused output folders.
# Default prompt style: constraints. Set A1_STYLE=direct|constraints|template.

REPEAT THE REQUIRED EXPERIMENT (from 01_code; bash)
for block in alu regfile extend controller; do
  for style in direct constraints template; do
    for run in 01 02; do
      A1_STYLE="$style" python student_code/lab1.py --spec "specs/$block.yaml" --out-dir "results/experiment/$block/$style/run-$run" --provider tamu
    done
  done
done

CHECK SUBMITTED FINALS (from 01_code; no API calls)
for block in alu regfile extend controller; do
  bash "module_packages/$block/scripts/run_$block.sh" "../02_hdl/final/$block.sv"
  mkdir -p "verify/$block"
  cp "../02_hdl/final/$block.sv" "verify/$block/final_rtl.sv"
  cp "../02_hdl/final/${block}_tb.sv" "verify/$block/${block}_tb.sv"
  bash run_generated_tb.sh "$block" "verify/$block"
done

Only marked Phase A/B/C regions of lab1.py were edited; no provided helper was
changed. Prompt text exports are copies for review; runtime templates stay in
lab1.py. Manifests retain historical absolute paths for provenance; their attempt
filenames map to 02_hdl/history with the same block/style/run hierarchy.
All unsuccessful attempts are retained. No API keys or secret files are included.
