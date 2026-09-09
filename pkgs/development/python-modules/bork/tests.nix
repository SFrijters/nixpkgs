{
  testers,

  bork,
  cacert,
  git,
  pytest,
}:
{
  # a.k.a. `tests.testers.runCommand.bork`
  pytest-network = testers.runCommand {
    name = "bork-pytest-network";
    nativeBuildInputs = [
      bork
      cacert
      git
      pytest
    ];
    script = ''
      # Copy the source tree over, and make it writeable
      cp -r ${bork.src} bork/
      find -type d -exec chmod 0755 '{}' '+'

      # Exclude the homf repository because it uses hatchling as a build system
      # and creating the appropriate environment fails.
      # This is not something we *need* to exercise runCommand
      substituteInPlace bork/tests/conftest.py \
        --replace-fail '"https://github.com/duckinator/homf.git",' ' '

      pytest -v -m network bork/
      touch $out
    '';
  };
}
