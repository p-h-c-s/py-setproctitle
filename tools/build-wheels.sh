#!/bin/bash
set -e -u -x

function repair_wheel {
    wheel="$1"
    if ! auditwheel show "$wheel"; then
        echo "Skipping non-platform wheel $wheel"
    else
        auditwheel repair "$wheel" --plat "$PLAT" -w /io/wheelhouse/
    fi
}

function supported {
    "$1/python" -c "import sys; sys.exit(0 if sys.version_info[:2] >= (3,6) else 1)"
}

# Compile wheels
for PYBIN in /opt/python/*/bin; do
    if ! supported $PYBIN; then continue; fi
    "${PYBIN}/pip" wheel /io/ --no-deps -w wheelhouse/
done

# Bundle external shared libraries into the wheels
for whl in wheelhouse/*.whl; do
    repair_wheel "$whl"
done

# Install packages and test
for PYBIN in /opt/python/*/bin/; do
    if ! supported $PYBIN; then continue; fi
    "${PYBIN}/pip" install setproctitle --no-index -f /io/wheelhouse
    "${PYBIN}/pip" install pytest
    (cd "$HOME"; "${PYBIN}/pytest" -m "not embedded" --color=yes -v /io/tests)
done
