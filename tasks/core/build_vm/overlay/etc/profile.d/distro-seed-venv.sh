export DS_PYTHON_VENV="${DS_PYTHON_VENV:-/opt/distro-seed/venv}"
if [ -r "${DS_PYTHON_VENV}/bin/activate" ]; then
	. "${DS_PYTHON_VENV}/bin/activate"
fi
