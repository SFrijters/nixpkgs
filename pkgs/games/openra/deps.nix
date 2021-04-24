{ fetchurl }: let

  fetchNuGet = { name, version, sha256 }: fetchurl {
    inherit sha256;
    url = "https://www.nuget.org/api/v2/package/${name}/${version}";
  };

in [

  (fetchNuGet {
    name = "DiscordRichPresence";
    version = "1.0.150";
    sha256 = "sha256-6eB1iJvUKbGERSlgfgj42wrD15DbdYQB4kNFxjSJq2I=";
  })

  (fetchNuGet {
    name = "Microsoft.NETFramework.ReferenceAssemblies";
    version = "1.0.0";
    sha256 = "sha256-6faPQ4jaFY3OGGVk3lZKW+DEZaIOBZ/wHqbiDTsRR1k=";
  })

  (fetchNuGet {
    name = "Microsoft.NETFramework.ReferenceAssemblies.net472";
    version = "1.0.0";
    sha256 = "sha256-LI/XnqGb0Dzs5A7ZK3uv3gJPh8c6vOvj7/jabgW2Ea8=";
  })

  (fetchNuGet {
    name = "Newtonsoft.Json";
    version = "12.0.2";
    sha256 = "sha256-BW7sXT2LKpP3ylsCbTTZ1f6Mg1sR4yL68aJVHaJcTnA=";
  })

  (fetchNuGet {
    name = "NuGet.CommandLine";
    version = "4.4.1";
    sha256 = "sha256-S6kkf08QIAAT42HzXfHhchevfy1ptkNOmYEJwRcs8+s=";
  })

  (fetchNuGet {
    name = "NUnit";
    version = "3.12.0";
    sha256 = "sha256-YrZ1FqCJUaILErAuXSC1BF7btofDqr6RcChuxbuQAKE=";
  })

  (fetchNuGet {
    name = "NUnit.Console";
    version = "3.11.1";
    sha256 = "sha256-moBpPxWZc8uOuom0/Pl2bq2DHyGbIb/CD4e08qI0lAM=";
  })

  (fetchNuGet {
    name = "NUnit.ConsoleRunner";
    version = "3.11.1";
    sha256 = "sha256-rUd49agYAdO/DiYyIad35KkKXxSswZ0aMBZsY5GnrcM=";
  })

  (fetchNuGet {
    name = "NUnit.Extension.NUnitProjectLoader";
    version = "3.6.0";
    sha256 = "sha256-b5MFQOEBCtKxcaTbmeJ4auVd6P49Xq4+SK9apxmMUtA=";
  })

  (fetchNuGet {
    name = "NUnit.Extension.NUnitV2Driver";
    version = "3.8.0";
    sha256 = "sha256-8pr8/hUJ46Hg5yR7HjxHESoZQfUQjpVXsdr9auJKor0=";
  })

  (fetchNuGet {
    name = "NUnit.Extension.NUnitV2ResultWriter";
    version = "3.6.0";
    sha256 = "sha256-KvO/CD3TSSF5hw/yyATd7D43RdPYEJvFaW/TIfP6tG0=";
  })

  (fetchNuGet {
    name = "NUnit.Extension.TeamCityEventListener";
    version = "1.0.7";
    sha256 = "sha256-+mzefd62LYpV4GnPFOUF2s6m1MJ5kr7nhG29UNwXfsI=";
  })

  (fetchNuGet {
    name = "NUnit.Extension.VSProjectLoader";
    version = "3.8.0";
    sha256 = "sha256-jtj+hG2LFSPuVoKbeD4ECPDlooFP4womR89RSe1XjRw=";
  })

  (fetchNuGet {
    name = "NUnit3TestAdapter";
    version = "3.16.1";
    sha256 = "sha256-CRPlYIerAqLMkbTy6HVvWjvyaf4jy3/Ud/rr5q6q8N8=";
  })

  (fetchNuGet {
    name = "OpenRA-Eluant";
    version = "1.0.17";
    sha256 = "sha256-zzodv5IYcjphm/KplemkM2QN1xfjjXQ8RGJif9vdQtk=";
  })

  (fetchNuGet {
    name = "OpenRA-Freetype6";
    version = "1.0.4";
    sha256 = "sha256-oYxaJZxiFIdW0sByJZAE7GSLVOsRE54VjNNn4BvZES0=";
  })

  (fetchNuGet {
    name = "OpenRA-FuzzyLogicLibrary";
    version = "1.0.1";
    sha256 = "sha256-NW5e5ywU8XUtVezB4lHQPc4mAK1zb3wnpSvrkAhawE4=";
  })

  (fetchNuGet {
    name = "OpenRA-Open.NAT";
    version = "1.0.0";
    sha256 = "sha256-a/ML2tn8fqYv4axeeHIHaevXiix21ct+zBagKZL71g8=";
  })

  (fetchNuGet {
    name = "OpenRA-OpenAL-CS";
    version = "1.0.16";
    sha256 = "sha256-6i66rpk2/sujjLOWFL18aA+Hhi9Sf+DQrBXPw1l989o=";
  })

  (fetchNuGet {
    name = "OpenRA-SDL2-CS";
    version = "1.0.28";
    sha256 = "sha256-N7gY3hj/akslkbc8NtLPPioBQTnRzomHlbLg2jD0Nwg=";
  })

  (fetchNuGet {
    name = "rix0rrr.BeaconLib";
    version = "1.0.2";
    sha256 = "sha256-pJx8BQ9KTR8coXSubUvotmMM0YaczLMh3NJsdOGJHjg=";
  })

  (fetchNuGet {
    name = "SharpZipLib";
    version = "1.2.0";
    sha256 = "sha256-peIXh6oQapmfaiKo2+xXSYsWeNwtay75GuJUOXHo0Ho=";
  })

  (fetchNuGet {
    name = "StyleCop.Analyzers";
    version = "1.1.118";
    sha256 = "sha256-CjC1f5z0sP15F6FeXqIDOtZLHqgjmQTzpsIrRkxXREI=";
  })


]
