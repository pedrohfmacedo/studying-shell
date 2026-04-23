#!/bin/bash

# Check if the project name was provided as an argument
if [ -z "$1" ]; then
 echo "Error: please provide the project name."
 echo "Usage: ./create_prj.sh <project_name>"
 exit 1
fi

PRJ_NAME=$1
BASE_DIR="prj/$PRJ_NAME"

# Check if the project directory already exists
if [ -d "$BASE_DIR" ]; then
 echo "Error: project '$PRJ_NAME' already exists."
 exit 1
fi

# =========================
# Create project structure
# =========================

# Frontend
mkdir -p "$BASE_DIR"/frontend/{constraints,lec,logs,parasitics,timing,work}
mkdir -p "$BASE_DIR"/frontend/reports/{area,power,timing}
mkdir -p "$BASE_DIR"/frontend/rtl/{src,tb}
mkdir -p "$BASE_DIR"/frontend/scripts/genus
mkdir -p "$BASE_DIR"/frontend/simulation/{gatelevel,rtl}
mkdir -p "$BASE_DIR"/frontend/structural/genus

# Verification
mkdir -p "$BASE_DIR"/verification/{docs,logs,reports,scripts,src,tb}

# Backend
mkdir -p "$BASE_DIR"/backend/{constraints,logs,outputs,parasitics,docs,physical,structural,work}
mkdir -p "$BASE_DIR"/backend/reports/{area,power,signoff,timing}

# DFT
mkdir -p "$BASE_DIR"/DFT/{constraints,logs,patterns,reports,scripts,work}

# Docs
mkdir -p "$BASE_DIR/docs"

# =========================
# Create placeholder files
# =========================

touch "$BASE_DIR"/frontend/{constraints,lec,logs,parasitics,timing,work}/.empty
touch "$BASE_DIR"/frontend/reports/{area,power,timing}/.empty
touch "$BASE_DIR"/frontend/rtl/{src,tb}/.empty
touch "$BASE_DIR"/frontend/scripts/genus/.empty
touch "$BASE_DIR"/frontend/simulation/{gatelevel,rtl}/.empty
touch "$BASE_DIR"/frontend/structural/genus/.empty

touch "$BASE_DIR"/verification/{docs,logs,reports,scripts,src,tb}/.empty

touch "$BASE_DIR"/backend/{constraints,logs,outputs,parasitics,docs,physical,structural,work}/.empty
touch "$BASE_DIR"/backend/reports/{area,power,signoff,timing}/.empty

touch "$BASE_DIR"/DFT/{constraints,logs,patterns,reports,scripts,work}/.empty

touch "$BASE_DIR/docs/.empty"

# Create README
touch "$BASE_DIR/docs/README.md"

echo "Project '$PRJ_NAME' successfully created inside prj/"