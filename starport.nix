{ buildGoModule, fetchFromGitHub, ... }:

buildGoModule rec {

  pname = "starport";
  version = "0.15.1";

  src = fetchFromGitHub {
    owner = "tendermint";
    repo = "starport";
    rev = "v${version}";
    sha256 = "1shvg4a24fz7nf9y7hj6dfg6c6if0lxqyfn4bax2n2an2i5dx4my";
  };

  vendorSha256 = "IyMzKGOdUH+7602v2yqw2YbHzNVhVmZ6ZCRxuo9brQc=";

  doCheck = false;

}
