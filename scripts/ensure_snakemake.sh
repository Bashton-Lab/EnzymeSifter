#!/usr/bin/env bash
#
# ensure_snakemake.sh
#
# Sourced by run_stage1.sh and run_stage2.sh.
#
# Guarantees that Snakemake is available before the pipeline runs, without
# asking the user to set up any environment by hand. Behaviour:
#
#   1. Require a base conda installation (the ONLY prerequisite the user must
#      provide themselves). If conda is missing, stop with a clear message.
#   2. On first run, create a dedicated conda environment ("enzymesifter")
#      containing Snakemake. On later runs this step is skipped.
#   3. Leave $ENV_NAME set so the caller can run Snakemake via `conda run`.
#
# We deliberately do NOT install conda for the user: doing so modifies their
# shell start-up files and is invasive. Requiring a base conda install is the
# standard convention for conda-based bioinformatics tools.

ENV_NAME="enzymesifter"
SNAKEMAKE_SPEC="snakemake-minimal>=9.0,<10"

# 1. conda must be present ---------------------------------------------------
if ! command -v conda &>/dev/null; then
    echo "Error: conda was not found on your PATH." >&2
    echo "" >&2
    echo "EnzymeSifter needs a base conda installation. We recommend Miniforge:" >&2
    echo "    https://github.com/conda-forge/miniforge" >&2
    echo "" >&2
    echo "Install it, restart your shell, then re-run this script." >&2
    exit 1
fi

# 2. Create the environment on first run -------------------------------------
if ! conda env list | grep -qE "^[[:space:]]*${ENV_NAME}[[:space:]]"; then
    echo "[setup] First run: creating the '${ENV_NAME}' environment with Snakemake..." >&2
    conda create -y -n "${ENV_NAME}" \
        -c conda-forge -c bioconda -c nodefaults \
        python">=3.9" "${SNAKEMAKE_SPEC}"
fi

# 3. Safety net: make sure Snakemake actually resolves inside the env --------
if ! conda run -n "${ENV_NAME}" snakemake --version &>/dev/null; then
    echo "[setup] Installing Snakemake into '${ENV_NAME}'..." >&2
    conda install -y -n "${ENV_NAME}" \
        -c conda-forge -c bioconda -c nodefaults "${SNAKEMAKE_SPEC}"
fi

echo "[setup] Using Snakemake $(conda run -n "${ENV_NAME}" snakemake --version) from the '${ENV_NAME}' environment." >&2
