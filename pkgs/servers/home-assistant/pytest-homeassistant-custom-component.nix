{
  lib,
  buildPythonPackage,
  pythonOlder,
  fetchFromGitHub,
  setuptools,
  aiohttp,
  bcrypt,
  freezegun,
  homeassistant,
  pytest-asyncio,
  pytest-socket,
  requests-mock,
  respx,
  syrupy,
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "pytest-homeassistant-custom-component";
  version = "0.13.320";
  pyproject = true;

  disabled = pythonOlder "3.13";

  src = fetchFromGitHub {
    owner = "MatthewFlamm";
    repo = "pytest-homeassistant-custom-component";
    tag = version;
    hash = "sha256-VweH6SWDYO9m0g2MS8awK00DwiflfPpyLep79U60uWw=";
  };

  patches = [
    # Update for Home Assistant 2026.4.0
    # https://github.com/MatthewFlamm/pytest-homeassistant-custom-component/pull/246
    ./patches/pytest-homeassistant-custom-component-246.patch
  ];

  build-system = [ setuptools ];

  pythonRemoveDeps = true;

  dependencies = [
    aiohttp
    bcrypt
    freezegun
    homeassistant
    pytest-asyncio
    pytest-socket
    requests-mock
    respx
    syrupy
  ];

  pythonImportsCheck = [ "pytest_homeassistant_custom_component.plugins" ];

  nativeCheckInputs = [ pytestCheckHook ];

  meta = {
    changelog = "https://github.com/MatthewFlamm/pytest-homeassistant-custom-component/blob/${src.tag}/CHANGELOG.md";
    description = "Package to automatically extract testing plugins from Home Assistant for custom component testing";
    homepage = "https://github.com/MatthewFlamm/pytest-homeassistant-custom-component";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ dotlambda ];
  };
}
