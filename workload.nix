# Auto-generated workload pack data. Do not edit.
{ mkPack, mkWorkload }:
let
  packs = {
    "Microsoft.NET.Runtime.MonoAOTCompiler.Task.net8" = mkPack {
      alias-to = {
        any = {
          pname = "Microsoft.NET.Runtime.MonoAOTCompiler.Task";
          hash = "sha512-w7N8YSCPB+JRHLl5XI44k7G+uW3+XuHrAhucrNn6EU9VrIoRnwiYaIZgdN4nRPboWr+U0gCaI2hrEfCvoD3AWQ==";
        };
      };
    };
    "Microsoft.NET.Runtime.MonoTargets.Sdk.net8" = mkPack {
      alias-to = {
        any = {
          pname = "Microsoft.NET.Runtime.MonoTargets.Sdk";
          hash = "sha512-Aon5a+5kXT073PAi9ONnGVdEMQKDYbG6xQjN66AXj50tztpy7tXbTuGSBVEco+7UVbHotjugKCBC4oUdJyFZXg==";
        };
      };
    };
    "Microsoft.NET.Runtime.LibraryBuilder.Sdk.net8" = mkPack {
      alias-to = {
        any = {
          pname = "Microsoft.NET.Runtime.LibraryBuilder.Sdk";
          hash = "sha512-Y/TZtmFSQGfNfHQ9vZX+J0iRKJwWUpb030DenE6lMXNdTh98HfyZVQYu4/7QXVcAF5Sg2vNU1ruoa9XFQpi2Lw==";
        };
      };
    };
    "Microsoft.NET.Runtime.WebAssembly.Sdk.net8" = mkPack {
      alias-to = {
        any = {
          pname = "Microsoft.NET.Runtime.WebAssembly.Sdk";
          hash = "sha512-NkyE3G7IMM0EqKuORfovZg2XdLHLxpaDs+BG9ZnPLlqORXYga6DHM3voeuqjte+LfPnHKiyXcwCeF7XNUdZgoQ==";
        };
      };
    };
    "Microsoft.NET.Runtime.WebAssembly.Wasi.Sdk.net8" = mkPack {
      alias-to = {
        any = {
          pname = "Microsoft.NET.Runtime.WebAssembly.Wasi.Sdk";
          hash = "sha512-2TzON115FwCm7UCmepRbUTNmHNR7y1K/Yh5pKbFFOFGD1DKcLChgdjehlAlKhcPPPpH8omI3A9CM5Q+WkiJ6wg==";
        };
      };
    };
    "Microsoft.NET.Runtime.WebAssembly.Templates.net8" = mkPack {
      alias-to = {
        any = {
          pname = "Microsoft.NET.Runtime.WebAssembly.Templates";
          hash = "sha512-5mCwntJe1bXKKSvcwpJBm7uB7le09LyJFAOMIMwEIdYBoHY6XMJ4HATmw4q6JWWO/sEJTPmaL0Bn+6604ZY96w==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.Mono.net8.android-arm" = mkPack {
      alias-to = {
        any = {
          pname = "Microsoft.NETCore.App.Runtime.Mono.android-arm";
          hash = "sha512-1gDH/DyW4BC2WyvD3EMfdwhva7ET6nWonhsFdobb5RdX0tNkDCg2CFeBHGFY9dv1DqwKoCBrtzvfSYs5KhyOYA==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.Mono.net8.android-arm64" = mkPack {
      alias-to = {
        any = {
          pname = "Microsoft.NETCore.App.Runtime.Mono.android-arm64";
          hash = "sha512-M52sHKOVB3X0RBzHKr6uikePXUt26ssH8/eM+95/CLzXLdE7C3/HWmdTBKX6ECfSYAawZryInzkeNALgowXuCQ==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.Mono.net8.android-x64" = mkPack {
      alias-to = {
        any = {
          pname = "Microsoft.NETCore.App.Runtime.Mono.android-x64";
          hash = "sha512-/R01BrSMCtBMShcgyo2puLHXEUv0O29jikoFsL+FfCR3ReCu4K89JE33yIAEG1tcwtco73ek4M4dkQ2ZcG/C2g==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.Mono.net8.android-x86" = mkPack {
      alias-to = {
        any = {
          pname = "Microsoft.NETCore.App.Runtime.Mono.android-x86";
          hash = "sha512-yMIyTPDLA30JwIIQNpeOKDrXAhaoG2+o1S29vGeHUvxbloioygQ7y8ApHwHhIsNBnf6WICHJK99qsqg7yXtdsA==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.AOT.Cross.net8.android-x86" = mkPack {
      alias-to = {
        win-x64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.win-x64.Cross.android-x86";
          hash = "sha512-WNndJ2n+MUjnZ+EXLCOuFQGyoWjwCf1OJHPOXXZS9hvqHIPFdsHtb0dFKwJ+UAgRoO+IqYm/JZl+MwBGLuQNZg==";
        };
        win-arm64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.win-x64.Cross.android-x86";
          hash = "sha512-WNndJ2n+MUjnZ+EXLCOuFQGyoWjwCf1OJHPOXXZS9hvqHIPFdsHtb0dFKwJ+UAgRoO+IqYm/JZl+MwBGLuQNZg==";
        };
        linux-x64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.linux-x64.Cross.android-x86";
          hash = "sha512-nnA+qJAyYsHGRB1yz0NrRyZOAFHmyHGiG9j7AcQOLniLNrEgG5Ywa7JuiWKKoGCUF/zLcQzceyBze7KtJFjnxw==";
        };
        linux-arm64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.linux-arm64.Cross.android-x86";
          hash = "sha512-j7IZ7opghbSQBxeUhR3rsHMGilV8anpici888qt27j0y7yP1I88cb6HWq0sUPTAOSZ5G15ms3zJN1tN0hOAmFw==";
        };
        osx-x64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.osx-x64.Cross.android-x86";
          hash = "sha512-JJ8lQLgTyOVs/04uzWGivtXxFtG/lvqh1XkdiTIpM51Q7ylbNTNo2CGdQYlWDJHbolFi9ia70LFNT39NuqpMng==";
        };
        osx-arm64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.osx-arm64.Cross.android-x86";
          hash = "sha512-lxqufBuA1wcpjYvSaaOC77M4k4M5FW/5zz1u8F31fxUQn/xY+oPeSXWSz6V7qHrR3ZwRksH0nwKl+Uem4qcF8A==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.AOT.Cross.net8.android-x64" = mkPack {
      alias-to = {
        win-x64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.win-x64.Cross.android-x64";
          hash = "sha512-GiV1rZ7+L7T1jOd2qA/6D5IK0sgrH3mqVkCb0Bv1oJO18CWXsgkXqFFQSc2PATtKHHC3U0Nh69C24ZceqZ5jbg==";
        };
        win-arm64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.win-x64.Cross.android-x64";
          hash = "sha512-GiV1rZ7+L7T1jOd2qA/6D5IK0sgrH3mqVkCb0Bv1oJO18CWXsgkXqFFQSc2PATtKHHC3U0Nh69C24ZceqZ5jbg==";
        };
        linux-x64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.linux-x64.Cross.android-x64";
          hash = "sha512-uYoyU2OqAcnMBnXxegelY5Hk/K/BeRR47iA3PE7bLeZSgdLbtQu0sZbKlP4Au6pwRwj2yx5kntOJ2AdiBE4bQg==";
        };
        linux-arm64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.linux-arm64.Cross.android-x64";
          hash = "sha512-aFi8nAKlYty6UWGbO1Vri2d510PybFZYNfdV04EvqA0sT+wfxEf+D0bwhvgvannUvQJjGdKyd0EAJsvaN6qmvQ==";
        };
        osx-x64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.osx-x64.Cross.android-x64";
          hash = "sha512-TArePh0cxE1yyJrO/vVwBDyyu74xWU7MHnNkkqMDsbWok4KrpZKvCAjxchkhP/AqCZ6o88OEDKlBmrlFXsOK1g==";
        };
        osx-arm64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.osx-arm64.Cross.android-x64";
          hash = "sha512-AIaycZYgPO4KAfvIyFrAg0tQ3cr7uC7GPH3MgekisHI1WbsQU3B7LwS9tGeMIDcCtqOtCE6XyWDSQtX3oDVYcQ==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.AOT.Cross.net8.android-arm" = mkPack {
      alias-to = {
        win-x64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.win-x64.Cross.android-arm";
          hash = "sha512-R1aPxvV99SolCbmz5fhh4H4QeBP2WaKvfkHuT9PWZDrCHsZsPn17YmE0E1iDgaSMFZisqv14WGH6WMXE7M8Nhw==";
        };
        win-arm64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.win-x64.Cross.android-arm";
          hash = "sha512-R1aPxvV99SolCbmz5fhh4H4QeBP2WaKvfkHuT9PWZDrCHsZsPn17YmE0E1iDgaSMFZisqv14WGH6WMXE7M8Nhw==";
        };
        linux-x64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.linux-x64.Cross.android-arm";
          hash = "sha512-7Qbr/rC5FoZk26xwxlxEsbfrWKbLul3wdzFZ0padj2ttts/r8IbOVWIfAE4KRvwyKLbf8qvqxQ3qBQpLjYD+gw==";
        };
        linux-arm64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.linux-arm64.Cross.android-arm";
          hash = "sha512-5HFUlA//6k7pPFNMdPfPYv3TT8GKiT93SOu1fpawX/pyqkIVbKTqXjqqhZLSTmbINcxGidEpfGkmINKYuTXHcA==";
        };
        osx-x64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.osx-x64.Cross.android-arm";
          hash = "sha512-ioGyC2tNyAi0HZYAf3R5erIQPhulWYxHdJJh1pkRctGr4/RL15zVHHLDXnrBKB+5DAvfwDMQPujUcLSCHxPz+A==";
        };
        osx-arm64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.osx-arm64.Cross.android-arm";
          hash = "sha512-l4F4s+31EbxE7P8AW9C/QBq3vF+YOhrIZ42PZyta2Ht8RXNzPtWdEzwqgIgyH2Da1mZwUPqr+9r3J4joScny6A==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.AOT.Cross.net8.android-arm64" = mkPack {
      alias-to = {
        win-x64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.win-x64.Cross.android-arm64";
          hash = "sha512-uqg/nD7BzeCiZCM4rWH2MHgBrpQgsXpOiUSUVenHeBUkm8CZcuxUA/ZL6BNB6WUofHrFbPPLCTDWuuBTjx8W5A==";
        };
        win-arm64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.win-x64.Cross.android-arm64";
          hash = "sha512-uqg/nD7BzeCiZCM4rWH2MHgBrpQgsXpOiUSUVenHeBUkm8CZcuxUA/ZL6BNB6WUofHrFbPPLCTDWuuBTjx8W5A==";
        };
        linux-x64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.linux-x64.Cross.android-arm64";
          hash = "sha512-NaiPzNkSy18ChkydZyOjOnqmgq0QQ/Zxda2yMsrw90SlNdLTb12i06qkp6yNILFLXeCzMg5UgoZSy0EVSFOqpQ==";
        };
        linux-arm64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.linux-arm64.Cross.android-arm64";
          hash = "sha512-d5zP43EGNwVIBr61+mzifg6j3gAdQq5Hu058v8UrfUITIKw1UvzgDQbrvi3pxbgiYvNDi5tuWAN3OUbpndaQpQ==";
        };
        osx-x64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.osx-x64.Cross.android-arm64";
          hash = "sha512-UwEG+w/zmbk0E+f5MJ8sZWnnxXXLpShhpF8VKONDjLvYFVheVx1vMFQ/zm9cIf1EXLN2PBTwt/fdJU2lLDBN5Q==";
        };
        osx-arm64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.osx-arm64.Cross.android-arm64";
          hash = "sha512-CMVocolp9/nAg0/ZZdAehHkpjqapMcyYGlDWYTnGaAGDRpk2lS/5PCODvVD105fC/Plhe6zw/lwPkcgZJk5GsQ==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.Mono.net8.maccatalyst-arm64" = mkPack {
      alias-to = {
        any = {
          pname = "Microsoft.NETCore.App.Runtime.Mono.maccatalyst-arm64";
          hash = "sha512-As8QQ95Af6DhgC3N+sgwD6H9+SIUQ/qbjb13mjyp7oPBhIEvzyWtVVaD6FOIbWyrAeyKeCCEtBlE/kmjrt2G7g==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.Mono.net8.maccatalyst-x64" = mkPack {
      alias-to = {
        any = {
          pname = "Microsoft.NETCore.App.Runtime.Mono.maccatalyst-x64";
          hash = "sha512-9wH6kUw3vEtj7LCZsclHeH+VVo3DribJDurL+tBtbsY/Rd/KWWLxut50fZ1lEyvVwDdQ0YMZz0xuJ4Ju6LN6aw==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.Mono.net8.osx-arm64" = mkPack {
      alias-to = {
        any = {
          pname = "Microsoft.NETCore.App.Runtime.Mono.osx-arm64";
          hash = "sha512-BlhX9ZFiZiLJjsnd+u3Es4SoF25Sseh13xVRuX9qSj+zbdDT0WrSc3AqKhX7T+iHYHmOvAhF6hVioCOXX3k25g==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.Mono.net8.osx-x64" = mkPack {
      alias-to = {
        any = {
          pname = "Microsoft.NETCore.App.Runtime.Mono.osx-x64";
          hash = "sha512-FoIQgcIP/UQMIgPDglDd3CwTeeABeHbeZwo92tVikOHfwRoZfJ6tU5CsouGD5OCSQp1tAA9NUqDWUTZw8zChDA==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.osx-arm64" = mkPack {
      pname = "Microsoft.NETCore.App.Runtime.Mono.osx-x64";
      hash = "sha512-UcgDIJx4+Zh3yNrnwDJoXlA9IpugIUDp0niYFyw/U18c9jI4MT51YGLGlI7vy7IkOVA7O0mJcLABrABLKlcKbg==";
    };
    "Microsoft.NETCore.App.Runtime.osx-x64" = mkPack {
      pname = "Microsoft.NETCore.App.Runtime.Mono.osx-x64";
      hash = "sha512-iufUmvbhlMAtLdFwCU1LFA17fFbhE/eYg6dLVxmPxvwPDVEyOoJqdlWQAH4vvOh8A2gTbEG56qSSWDKmUuq37g==";
    };
    "Microsoft.NETCore.App.Runtime.Mono.net8.ios-arm64" = mkPack {
      alias-to = {
        any = {
          pname = "Microsoft.NETCore.App.Runtime.Mono.ios-arm64";
          hash = "sha512-mr+VAhwGBFnFvw8mgu47BIameyn47ehB4hesFD2Tlwl9xIEV2kF0q6LpB+LxsQfTgKMhCvC8QhKkPeS+DA+5ng==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.Mono.net8.iossimulator-arm64" = mkPack {
      alias-to = {
        any = {
          pname = "Microsoft.NETCore.App.Runtime.Mono.iossimulator-arm64";
          hash = "sha512-M0A2oN5xaDCgkrOhM9FqGvb7BgIp/Au+cGjUKxzgXj7qxvpWstuDWn2/0ukWuKZUmDxpADNxCNIw0xdMj8tkjg==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.Mono.net8.iossimulator-x64" = mkPack {
      alias-to = {
        any = {
          pname = "Microsoft.NETCore.App.Runtime.Mono.iossimulator-x64";
          hash = "sha512-tkJfc/chWGeGCppPzBHrhE4PnTDIPhUfueQRGKfjbanIIO2LaaXP0BdIpuBeFj5djzSZ49mVg3Tb7EVAmf+N8A==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.AOT.Cross.net8.tvos-arm64" = mkPack {
      alias-to = {
        osx-x64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.osx-x64.Cross.tvos-arm64";
          hash = "sha512-5yo9CoGkZxn3g/Ti9YkVw40lppQSOIF+tg7Px5RTRxMI3d/sVET8JxPVgB/OJy7oGiRV1+0+0Rj3typ4eW7fPQ==";
        };
        osx-arm64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.osx-arm64.Cross.tvos-arm64";
          hash = "sha512-+PZKiRgrQ1aNt2ulvybNm1gP3sA4qm0HgGCpt+F6b6xEWrYsaAMtj/H0yQuRWtjNB2CE1T6T/wsyp265Blbinw==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.Mono.net8.tvos-arm64" = mkPack {
      alias-to = {
        any = {
          pname = "Microsoft.NETCore.App.Runtime.Mono.tvos-arm64";
          hash = "sha512-Ukfcc9lakLVji4T4TsTEbyTbNYkF/qXGBnm8c2LuHyrgTNNXiS2NPffmfw5p0+BmBcaSuKaWV/4wWbtPPnDE/g==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.Mono.net8.tvossimulator-arm64" = mkPack {
      alias-to = {
        any = {
          pname = "Microsoft.NETCore.App.Runtime.Mono.tvossimulator-arm64";
          hash = "sha512-HiL2gOVjV4ArhZWlb6wZuxFGVSHuG4d5gmMcZk9EZzS39DQnexHA1dBpaJ1kQnNLkQR+vlRrim/lzW92LoUPgA==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.Mono.net8.tvossimulator-x64" = mkPack {
      alias-to = {
        any = {
          pname = "Microsoft.NETCore.App.Runtime.Mono.tvossimulator-x64";
          hash = "sha512-SNp/V3yfXqDnY6cTsmVzCEICqHwibazBTCVsSIrJjDpQnkdMYHwXC8Yi71F74C7kfvSMsIsQNp8rjXRPGAjLaw==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.AOT.Cross.net8.maccatalyst-arm64" = mkPack {
      alias-to = {
        osx-arm64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.osx-arm64.Cross.maccatalyst-arm64";
          hash = "sha512-iXM/EY7GVqL1QvefQjnEI9kS+cw59GDQro//QTXzVbG9MakTAqfNFV25VOvDj4PGtTslFUGsVg91Q9MZNaTS9g==";
        };
        osx-x64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.osx-x64.Cross.maccatalyst-arm64";
          hash = "sha512-M06gyggmyUeYteFsssLJFFwFZ8V9U/x5AwOONArALEl1bcnJz54cYyv1UnR0ThdIkmnglcPIqkkF2fYhAr31xg==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.AOT.Cross.net8.maccatalyst-x64" = mkPack {
      alias-to = {
        osx-arm64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.osx-arm64.Cross.maccatalyst-x64";
          hash = "sha512-3TTKifz30/Nr6JgVqQl4E9v28+iu/iyUF2ufgDq12jMX9nNnnXxgTTLBATQsQfX9ZrUBlBaOAPBc/zdqio81ZA==";
        };
        osx-x64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.osx-x64.Cross.maccatalyst-x64";
          hash = "sha512-h2ltlaa95pD/wQXhtnj41VoJIoQytriQnZxVacx+TuIse+4aDWqVDr1jKoEqtxc8PVIbiG7dfHKO5Z7QRTJO/g==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.AOT.Cross.net8.tvossimulator-arm64" = mkPack {
      alias-to = {
        osx-arm64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.osx-arm64.Cross.tvossimulator-arm64";
          hash = "sha512-76hbTGmSTiRt+ZPcVN9J+Fg8bjHeyToiu+kR6Qa3PRRHIGxXIylX3KQRw3VSrzUS9f2DclUBNH7YZm9YsouIMg==";
        };
        osx-x64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.osx-x64.Cross.tvossimulator-arm64";
          hash = "sha512-HQgp2OWRy4GS760J0kj7aPHmQMQgYqNTuThJi+xFEpTnLHYvilg/Z5p1BP+HAC2AvE9jwhO+F5q8G3A4p6t2NA==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.AOT.Cross.net8.tvossimulator-x64" = mkPack {
      alias-to = {
        osx-arm64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.osx-arm64.Cross.tvossimulator-x64";
          hash = "sha512-HczUlsbslG7ncsF/fZuJPmNCw8vtCsarSYfIci7DcihLwULw0yKziCvfY18uutXKpYazdfpdubE932zNgpVx7A==";
        };
        osx-x64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.osx-x64.Cross.tvossimulator-x64";
          hash = "sha512-LUEVBtqPk0auPA3kSPOVUYMbh134PBp0b5W5+hACu5tcn/J1S+Xxj7sgeex5VGLyyMdEvaQRgxL3E4Xx2Ob1Rw==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.AOT.Cross.net8.ios-arm64" = mkPack {
      alias-to = {
        osx-x64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.osx-x64.Cross.ios-arm64";
          hash = "sha512-GlFESo26wBWJI0JjLN7gJBiijdF2gr6NF9oAJrePrfZDMug82dwvBGQJEQgoiDn4G6dekElG2o9GPnnkNtVeUw==";
        };
        osx-arm64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.osx-arm64.Cross.ios-arm64";
          hash = "sha512-HMtVrVm4AleP7mlM5HBN2fkqf6X/naz0Fw5c+De7V3RlpI1rqZVjGc04JJAGu/eIzUWPTy6Ye3YFqPzd9mt4HQ==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.AOT.Cross.net8.iossimulator-arm64" = mkPack {
      alias-to = {
        osx-arm64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.osx-arm64.Cross.iossimulator-arm64";
          hash = "sha512-ktCMOSOAnJ1f4pfToz/qhDAu7J5276j+8a2Uvdks+8PnR7SEA4Mh/CzoIGWPMPjtz42WdPxpgitG83SZtzVgKw==";
        };
        osx-x64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.osx-x64.Cross.iossimulator-arm64";
          hash = "sha512-QBo2ziiJYqy/5pSJIZab6NGqnpq6dwniAf0msT7gXL5w6tdzYMclXrMK4UZCNgLmsolmEmOxiOq0dkbv9HEAqg==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.AOT.Cross.net8.iossimulator-x64" = mkPack {
      alias-to = {
        osx-arm64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.osx-arm64.Cross.iossimulator-x64";
          hash = "sha512-YS1BOhgto9wt8Qi7NzDG4SzDBJqMYbQa43mkp/RDDYUkSTJZHdJNRAM7wsT0S3/9tEDIJDLBpGu3E7Uha88XyA==";
        };
        osx-x64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.osx-x64.Cross.iossimulator-x64";
          hash = "sha512-kqCuOgh4sGHoK8eT8UOqtrp47L0ijj8E/7eQrkO+TFRULSPaWima0XMphawGWBa5KgXQnqlfHgJoWmsj1/tRZA==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.AOT.Cross.net8.browser-wasm" = mkPack {
      alias-to = {
        win-x64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.win-x64.Cross.browser-wasm";
          hash = "sha512-rQR4lEZ4Lz91WMeaZ2ApwEAvmYAIDnbEMfKu3HTIMOIstZ3OmPCtjCrstn93Pk6MZFmqaa/wLAPqgJwhPsloyQ==";
        };
        win-arm64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.win-x64.Cross.browser-wasm";
          hash = "sha512-rQR4lEZ4Lz91WMeaZ2ApwEAvmYAIDnbEMfKu3HTIMOIstZ3OmPCtjCrstn93Pk6MZFmqaa/wLAPqgJwhPsloyQ==";
        };
        linux-x64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.linux-x64.Cross.browser-wasm";
          hash = "sha512-bUopSekCKjagsmNkbCIcGSoYgR7jjxzHjv35pGr22dizPC2pQYbF/Pb/CPAFF44SON8LAKNJiTaXWzUO5mHaWw==";
        };
        linux-arm64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.linux-arm64.Cross.browser-wasm";
          hash = "sha512-Vg/cuJKpwcBqTG6bU2TjmCCu2vc4/hD0TJ2ieP+BrAn0ioCYh3GaI/mmFCTa2fVqubNC6L2cRZoJPA39EB2mmQ==";
        };
        osx-x64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.osx-x64.Cross.browser-wasm";
          hash = "sha512-58CcKqiFSPPvRQRXdQ7EsnGkHY0kLLNd/5kXHitNey5x2j9pGPmSa9kBaexKQRsAPeT4OtkIvNy4vfGJdtla5A==";
        };
        osx-arm64 = {
          pname = "Microsoft.NETCore.App.Runtime.AOT.osx-arm64.Cross.browser-wasm";
          hash = "sha512-iJYf6CSQ/3NOR64c9Db/BSrjORIE7bTW6v3wO3TvScrqro/NjQjdevg/cO50mWA30XdCdl6ezuGZICbSifdnJw==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.Mono.net8.browser-wasm" = mkPack {
      alias-to = {
        any = {
          pname = "Microsoft.NETCore.App.Runtime.Mono.browser-wasm";
          hash = "sha512-aQSJV0/XNjaUT0rO4tzchrxwHf73MB2/J9nbo6boLGtFv5deTpv8iOnc44mHNFaU9tHjTlTp58i6XJtFXlFU6w==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.Mono.multithread.net8.browser-wasm" = mkPack {
      alias-to = {
        any = {
          pname = "Microsoft.NETCore.App.Runtime.Mono.multithread.browser-wasm";
          hash = "sha512-w+3ktZCLy/Yr8Pz11i6ZHR02RHFFkoMTk4s2aS7iIZDmLDh2LgthZE9okMcFEOosRo0IRFVbbdBXdM9OKpFNzA==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.Mono.net8.wasi-wasm" = mkPack {
      alias-to = {
        any = {
          pname = "Microsoft.NETCore.App.Runtime.Mono.wasi-wasm";
          hash = "sha512-5d1ZZQ9hGRwIh06bRsJwcSQLtjFBbBgtMwpUrGz48ah7nDhwrTTl6uot17AF9V/mCe3vaI+xDSJGDiveIfQcsA==";
        };
      };
    };
    "Microsoft.NETCore.App.Runtime.win-x64" = mkPack {
      pname = "Microsoft.NETCore.App.Runtime.Mono.wasi-wasm";
      hash = "sha512-UkxLgMmbfnG+xF0G8t1Pd92UII+9KqgmxKNzejjTW1Ox+DCwrC05MmplM76vLsDOdaO87is325RbtdNRSaiERw==";
    };
    "Microsoft.NETCore.App.Runtime.win-x86" = mkPack {
      pname = "Microsoft.NETCore.App.Runtime.Mono.wasi-wasm";
      hash = "sha512-pxV9H1TBTznSSjg6EJUwh6HzAHN13sPqSFcLznfoTeDiq+VFt+vbCbuGR/QZIW2fiT85sP89r98t0BZlH9JG8A==";
    };
    "Microsoft.NETCore.App.Runtime.win-arm64" = mkPack {
      pname = "Microsoft.NETCore.App.Runtime.Mono.wasi-wasm";
      hash = "sha512-gK/53iv85vbUPb8CnLh6PPWxS9EHwtIPPPcxHFKTgNPO0mcXB+e3P5svSuEvfe9Yp/dE4l2E9UfDugcNSa8JxA==";
    };
  };

  workloads = {
    wasm-tools = mkWorkload {
      packs = [
        packs."Microsoft.NET.Runtime.WebAssembly.Sdk.net8"
        packs."Microsoft.NETCore.App.Runtime.Mono.net8.browser-wasm"
        packs."Microsoft.NETCore.App.Runtime.AOT.Cross.net8.browser-wasm"
      ];
      extends = [
        workloads.microsoft-net-runtime-mono-tooling
        workloads.microsoft-net-sdk-emscripten
      ];
    };
    wasm-experimental = mkWorkload {
      packs = [
        packs."Microsoft.NET.Runtime.WebAssembly.Templates.net8"
        packs."Microsoft.NETCore.App.Runtime.Mono.multithread.net8.browser-wasm"
      ];
      extends = [
        workloads.wasm-tools
      ];
    };
    wasi-experimental = mkWorkload {
      packs = [
        packs."Microsoft.NET.Runtime.WebAssembly.Wasi.Sdk.net8"
        packs."Microsoft.NETCore.App.Runtime.Mono.net8.wasi-wasm"
        packs."Microsoft.NET.Runtime.WebAssembly.Templates.net8"
      ];
      extends = [
        workloads.microsoft-net-runtime-mono-tooling
      ];
    };
    mobile-librarybuilder = mkWorkload {
      packs = [
        packs."Microsoft.NET.Runtime.LibraryBuilder.Sdk.net8"
      ];
      extends = [
        workloads.microsoft-net-runtime-android-aot
        workloads.microsoft-net-runtime-ios
        workloads.microsoft-net-runtime-maccatalyst
        workloads.microsoft-net-runtime-tvos
      ];
    };
    microsoft-net-runtime-android = mkWorkload {
      packs = [
        packs."Microsoft.NETCore.App.Runtime.Mono.net8.android-arm"
        packs."Microsoft.NETCore.App.Runtime.Mono.net8.android-arm64"
        packs."Microsoft.NETCore.App.Runtime.Mono.net8.android-x64"
        packs."Microsoft.NETCore.App.Runtime.Mono.net8.android-x86"
      ];
      extends = [
        workloads.microsoft-net-runtime-mono-tooling
      ];
    };
    microsoft-net-runtime-android-aot = mkWorkload {
      packs = [
        packs."Microsoft.NETCore.App.Runtime.AOT.Cross.net8.android-x86"
        packs."Microsoft.NETCore.App.Runtime.AOT.Cross.net8.android-x64"
        packs."Microsoft.NETCore.App.Runtime.AOT.Cross.net8.android-arm"
        packs."Microsoft.NETCore.App.Runtime.AOT.Cross.net8.android-arm64"
      ];
      extends = [
        workloads.microsoft-net-runtime-android
      ];
    };
    microsoft-net-runtime-ios = mkWorkload {
      packs = [
        packs."Microsoft.NETCore.App.Runtime.AOT.Cross.net8.ios-arm64"
        packs."Microsoft.NETCore.App.Runtime.AOT.Cross.net8.iossimulator-arm64"
        packs."Microsoft.NETCore.App.Runtime.AOT.Cross.net8.iossimulator-x64"
      ];
      extends = [
        workloads.runtimes-ios
      ];
    };
    runtimes-ios = mkWorkload {
      packs = [
        packs."Microsoft.NETCore.App.Runtime.Mono.net8.ios-arm64"
        packs."Microsoft.NETCore.App.Runtime.Mono.net8.iossimulator-arm64"
        packs."Microsoft.NETCore.App.Runtime.Mono.net8.iossimulator-x64"
      ];
      extends = [
        workloads.microsoft-net-runtime-mono-tooling
      ];
    };
    microsoft-net-runtime-maccatalyst = mkWorkload {
      packs = [
        packs."Microsoft.NETCore.App.Runtime.AOT.Cross.net8.maccatalyst-arm64"
        packs."Microsoft.NETCore.App.Runtime.AOT.Cross.net8.maccatalyst-x64"
      ];
      extends = [
        workloads.runtimes-maccatalyst
      ];
    };
    runtimes-maccatalyst = mkWorkload {
      packs = [
        packs."Microsoft.NETCore.App.Runtime.Mono.net8.maccatalyst-arm64"
        packs."Microsoft.NETCore.App.Runtime.Mono.net8.maccatalyst-x64"
      ];
      extends = [
        workloads.microsoft-net-runtime-mono-tooling
      ];
    };
    microsoft-net-runtime-macos = mkWorkload {
      packs = [
        packs."Microsoft.NETCore.App.Runtime.Mono.net8.osx-arm64"
        packs."Microsoft.NETCore.App.Runtime.Mono.net8.osx-x64"
        packs."Microsoft.NETCore.App.Runtime.osx-arm64"
        packs."Microsoft.NETCore.App.Runtime.osx-x64"
      ];
      extends = [
        workloads.microsoft-net-runtime-mono-tooling
      ];
    };
    microsoft-net-runtime-tvos = mkWorkload {
      packs = [
        packs."Microsoft.NETCore.App.Runtime.AOT.Cross.net8.tvos-arm64"
        packs."Microsoft.NETCore.App.Runtime.AOT.Cross.net8.tvossimulator-arm64"
        packs."Microsoft.NETCore.App.Runtime.AOT.Cross.net8.tvossimulator-x64"
      ];
      extends = [
        workloads.runtimes-tvos
      ];
    };
    runtimes-tvos = mkWorkload {
      packs = [
        packs."Microsoft.NETCore.App.Runtime.Mono.net8.tvos-arm64"
        packs."Microsoft.NETCore.App.Runtime.Mono.net8.tvossimulator-arm64"
        packs."Microsoft.NETCore.App.Runtime.Mono.net8.tvossimulator-x64"
      ];
      extends = [
        workloads.microsoft-net-runtime-mono-tooling
      ];
    };
    runtimes-windows = mkWorkload {
      packs = [
        packs."Microsoft.NETCore.App.Runtime.win-x64"
        packs."Microsoft.NETCore.App.Runtime.win-x86"
        packs."Microsoft.NETCore.App.Runtime.win-arm64"
      ];
    };
    microsoft-net-runtime-mono-tooling = mkWorkload {
      packs = [
        packs."Microsoft.NET.Runtime.MonoAOTCompiler.Task.net8"
        packs."Microsoft.NET.Runtime.MonoTargets.Sdk.net8"
      ];
    };
  };
in
workloads
