#!/bin/bash
set -euxo pipefail
. .ci/_source_common_env.sh
#if [ ! -d $PYTHONUSERBASE ]; then mkdir -p $PYTHONUSERBASE; fi

PYTHON=python
INSTALL_PIP_FLAGS="--cache-dir $CACHE_ROOT/pip_cache ${INSTALL_PIP_FLAGS:-}"  # --user
for pypkg in pyodeint pygslodeiv2 pycompilation pycodeexport pycvodes pykinsol sym pyodesys; do
    case $pypkg in
        sym)
            pypkg_fqn="git+https://github.com/bjodah/sym@jun21#egg=sym"
            ;;
        pyodeint)
            pypkg_fqn="git+https://github.com/bjodah/pyodeint@sep21#egg=pyodeint"
            ;;
        pygslodeiv2)
            pypkg_fqn="git+https://github.com/bjodah/pygslodeiv2@cython-except-plus#egg=pygslodeiv2"
            ;;
        pycompilation)
            pypkg_fqn="git+https://github.com/bjodah/pycompilation@master#egg=pycompilation"
            ;;
        pycodeexport)
            pypkg_fqn="git+https://github.com/bjodah/pycodeexport@master#egg=pycodeexport"
            ;;
        pycvodes)
            pypkg_fqn="git+https://github.com/bjodah/pycvodes@may21#egg=pycvodes"
            ;;
        pyodesys)
            pypkg_fqn="git+https://github.com/bjodah/pyodesys@bdf2#egg=pyodesys"
            ;;
        pykinsol)
            pypkg_fqn="git+https://github.com/bjodah/pykinsol@jan25#egg=pykinsol"
            ;;
        *)
            pypkg_fqn=$pypkg
            ;;
    esac
    $PYTHON -m pip install $INSTALL_PIP_FLAGS $pypkg_fqn
    #( cd /tmp; $PYTHON -m pytest -k "not pool_discontinuity_approx" --pyargs $pypkg )
done

$PYTHON -c "import pycvodes; import pyodesys; import pygslodeiv2"
$PYTHON -m pip install $INSTALL_PIP_FLAGS -e .[all]
[[ $(python3 setup.py --version) =~ ^[0-9]+.* ]]
git fetch -tq
cp -ra "$(pwd)" /dev/shm/          # some issue with filesystem on CI server (race conditions)
cd "/dev/shm/$(basename $(pwd))"   # running in /dev/shm (RAM backed) seems to help.
$PYTHON -m build --sdist                   # test pip installable sdist (checks MANIFEST.in)
git archive -o dist/chempy-head.zip HEAD  # test pip installable zip (symlinks break)
cd -
cp -ra "/dev/shm/$(basename $(pwd))/dist" .
rm -r "/dev/shm/$(basename $(pwd))"
