{
  lib,
  stdenv,
  buildVscode,
  fetchurl,
  writeShellScript,
  coreutils,
  commandLineArgs ? "",
  useVSCodeRipgrep ? stdenv.hostPlatform.isDarwin,
}:

let
  inherit (stdenv) hostPlatform;
  information = (lib.importJSON ./information.json);
  source =
    information.sources."${hostPlatform.system}"
      or (throw "antigravity-ide: unsupported system ${hostPlatform.system}");
in
(buildVscode {
  inherit commandLineArgs useVSCodeRipgrep;
  inherit (information) version vscodeVersion;
  pname = "antigravity-ide";

  executableName = "antigravity-ide";
  longName = "Antigravity IDE";
  shortName = "Antigravity IDE";
  libraryName = "antigravity-ide";
  iconName = "antigravity-ide";

  src = fetchurl { inherit (source) url sha256; };

  sourceRoot = if hostPlatform.isDarwin then "Antigravity IDE.app" else "Antigravity IDE";

  tests = { };
  updateScript = ./update.js;

  # When running inside an FHS environment, try linking Google Chrome or Chromium
  # to the hardcoded Playwright search path: /opt/google/chrome/chrome
  customizeFHSEnv =
    args:
    args
    // {
      extraBwrapArgs = (args.extraBwrapArgs or [ ]) ++ [ "--tmpfs /opt/google/chrome" ];
      extraBuildCommands = (args.extraBuildCommands or "") + ''
        mkdir -p "$out/opt/google/chrome"
      '';
      runScript = writeShellScript "antigravity-ide-wrapper" ''
        for candidate in google-chrome-stable google-chrome chromium-browser chromium; do
          if target=$(command -v "$candidate"); then
            ${coreutils}/bin/ln -sf "$target" /opt/google/chrome/chrome
            break
          fi
        done
        exec ${args.runScript} "$@"
      '';
    };

  meta = {
    mainProgram = "antigravity-ide";
    description = "Agentic development platform, evolving the IDE into the agent-first era";
    homepage = "https://antigravity.google/product/antigravity-ide";
    downloadPage = "https://antigravity.google/download#antigravity-ide";
    changelog = "https://antigravity.google/changelog";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    maintainers = with lib.maintainers; [
      xiaoxiangmoe
      Zaczero
      schembriaiden
    ];
  };
}).overrideAttrs (oldAttrs: {
  # On NixOS the agent is broken out of the box. The bundled
  # `language_server_linux_x64` binary (which powers the agent, including its
  # terminal) re-execs itself inside Antigravity's own nsjail sandbox, and that
  # jail bind-mounts the host's `/lib`, `/lib64`, `/usr`, `/bin` (all empty or
  # minimal on NixOS) plus every directory on the process's `$PATH` — and
  # nothing else. On a normal FHS distro that is enough, because `/usr` + `/lib`
  # contain every binary and library. NixOS instead scatters everything across
  # `/nix/store` and reaches it through symlink farms (`/run/current-system/sw/
  # bin`, `/etc/profiles/...`); the jail mounts those farm dirs but not their
  # store targets, so binaries (even the glibc loader the language server needs)
  # resolve to dangling links and the agent dies with `execve(...): No such file
  # or directory` / `exec: "bash": executable file not found in $PATH`.
  #
  # Putting `/nix/store` on `$PATH` makes nsjail bind-mount the store read-only
  # into the jail, which is the NixOS analogue of the `/usr` + `/lib` mount it
  # already relies on elsewhere: every farm symlink resolves and every library
  # loads, for any tool, with no per-binary patching. The store is world-
  # readable and — by Nix convention, which secret managers like sops-nix/agenix
  # enforce — contains no plaintext secrets, so this exposes nothing a process
  # running as the user cannot already read. (`/nix/store` holds only
  # subdirectories, so adding it to `$PATH` is a no-op for normal command
  # lookup; it serves purely as the sandbox-mount lever.)
  preFixup = (oldAttrs.preFixup or "") + ''
    gappsWrapperArgs+=(
      --prefix PATH : "/nix/store"
    )
  '';
})
