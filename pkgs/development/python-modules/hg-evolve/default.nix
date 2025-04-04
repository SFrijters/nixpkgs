{
  lib,
  buildPythonPackage,
  fetchPypi,
  mercurial,
}:

buildPythonPackage rec {
  pname = "hg-evolve";
  version = "11.1.7.post1";
  format = "setuptools";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-2HQ1suTpNhiiMDef470+Lp/tRMvU0vUM0Vq3AEb6i24=";
  };

  nativeCheckInputs = [ mercurial ];

  checkPhase = ''
    runHook preCheck

    export TESTTMP=$(mktemp -d)
    export HOME=$TESTTMP
    cat <<EOF >$HOME/.hgrc
    [extensions]
    evolve =
    topic =
    EOF

    # Shipped tests use the mercurial testing framework, and produce inconsistent results.
    # Do a quick smoke-test to see if things do what we expect.
    hg init $TESTTMP/repo
    pushd $TESTTMP/repo
    touch a
    hg add a
    hg commit -m "init a"
    hg topic something

    touch b
    hg add b
    hg commit -m "init b"

    echo hi > b
    hg amend

    hg obslog
    popd

    runHook postCheck
  '';

  meta = with lib; {
    description = "Enables the “changeset evolution” feature of Mercurial core";
    homepage = "https://www.mercurial-scm.org/doc/evolution/";
    maintainers = with maintainers; [
      xavierzwirtz
      lukegb
    ];
    license = licenses.gpl2Plus;
  };
}
