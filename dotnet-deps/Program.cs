using NuGet.Common;
using NuGet.Configuration;
using NuGet.DependencyResolver;
using NuGet.Frameworks;
using NuGet.LibraryModel;
using NuGet.Packaging;
using NuGet.Packaging.Core;
using NuGet.Protocol;
using NuGet.Protocol.Core.Types;
using NuGet.Versioning;

using Newtonsoft.Json;

using CancellationTokenSource cancellationTokenSource = new();

Console.CancelKeyPress += (sender, args) => {
    args.Cancel = true;
    cancellationTokenSource.Cancel(true);
};

var source = "https://api.nuget.org/v3/index.json";
var allPackages = false;
var writeHashes = true;

ILogger logger = NullLogger.Instance;
CancellationToken cancellationToken = cancellationTokenSource.Token;

SourceCacheContext cache = new ();
var repository = Repository.Factory.GetCoreV3(source);

var packages = new List<(
    PackageIdentity PackageIdentity,
    IEnumerable<PackageDependencyGroup> DependencyGroups)>();

var resource = await repository.GetResourceAsync<FindPackageByIdResource>();

if (allPackages) {
    var list = await repository.GetResourceAsync<ListResource>();

    var all = await list.ListAsync("", false, false, false, logger, cancellationToken);

    for(var e = all.GetEnumeratorAsync(); await e.MoveNextAsync();) {
        packages.Add((e.Current.Identity, e.Current.DependencySets));
    }
} else {
    var queue = new Queue<string>(new [] {
        // "Avalonia.Angle.Windows.Natives",
        // "HarfBuzzSharp",
        // "HarfBuzzSharp.NativeAssets.Linux",
        // "HarfBuzzSharp.NativeAssets.WebAssembly",
        // "MicroCom.Runtime",
        // "Microsoft.AspNetCore.Components.Web",
        // "Microsoft.Bcl.AsyncInterfaces",
        "Microsoft.CodeAnalysis.CSharp",
        // "Microsoft.CodeAnalysis.CSharp.Scripting",
        // "Microsoft.CodeAnalysis.CSharp.Workspaces",
        // "Microsoft.CodeAnalysis.Common",
        // "NUnit",
        // "Quamotion.RemoteViewing",
        // "ReactiveUI",
        // "SharpDX",
        // "SharpDX.DXGI",
        // "SharpDX.Direct2D1",
        // "SharpDX.Direct3D11",
        // "SkiaSharp",
        // "SkiaSharp.NativeAssets.Linux",
        // "SkiaSharp.NativeAssets.WebAssembly",
        // "System.ComponentModel.Annotations",
        // "System.Reactive",
        // "Tmds.DBus.Protocol",
        // "xunit.core",
    });

    var seen = new HashSet<string>(queue);

    var context = new RemoteWalkContext(cache, new PackageSourceMapping(new Dictionary<string, IReadOnlyList<string>>()), logger);

    var walker = new RemoteDependencyWalker(context);

    var graph = await walker.WalkAsync(
        new LibraryRange("Microsoft.CodeAnalysis.CSharp", new VersionRange(new NuGetVersion("4.10.0")), LibraryDependencyTarget.All),
        new NuGetFramework("net6.0"),
        null,
        null,
        true);

    GraphOperations.Dump(graph, Console.WriteLine);
    Console.WriteLine($"{repository.GetType()} {graph.Item.Data.Dependencies.Count}");

    Environment.Exit(0);
    while (queue.TryDequeue(out var id)) {
        IEnumerable<NuGetVersion> versions = await resource.GetAllVersionsAsync(
            id,
            cache,
            logger,
            cancellationToken);

        var latest = versions.Where(x => !x.IsPrerelease).Max();

        var deps = await resource.GetDependencyInfoAsync(id, latest, cache, logger, cancellationToken);

        packages.Add((deps.PackageIdentity, deps.DependencyGroups));

        foreach (var dep in
            deps.DependencyGroups
            .SelectMany(x => x.Packages)
            .Select(x => x.Id) .Where(x => !seen.Contains(x))) {
            if (!seen.Contains(dep)) {
                seen.Add(dep);
                queue.Enqueue(dep);
            }
        }
    }
}

using var writer = new JsonTextWriter(Console.Out) {
    Formatting = Formatting.Indented,
};

JsonSerializer serializer = new ();

writer.WriteStartArray();

foreach (var deps in packages.OrderBy(x => x.PackageIdentity)) {
    var identity = deps.PackageIdentity;

    string? hash = null;
    if (writeHashes) {
        using var downloader = await resource.GetPackageDownloaderAsync(identity, cache, logger, cancellationToken);
        var tmp = Path.GetTempFileName();
        try {
            await downloader.CopyNupkgFileToAsync(tmp, cancellationToken);
            hash = await downloader.GetPackageHashAsync("sha256", cancellationToken);
            hash = $"sha256-{hash}";
        } finally {
            File.Delete(tmp);
        }
    }

    var package = new {
        id = identity.Id,
        version = identity.Version,
        hash,
        dependencies = deps.DependencyGroups.Where(g => g.Packages.Any()).Select(g => new {
            framework = g.TargetFramework.ToString(),
            packages = g.Packages.Select(p => new {
                id = p.Id,
                version = p.VersionRange.OriginalString,
            }),
        }),
    };

    serializer.Serialize(writer, package);
}

writer.WriteEndArray();
Console.WriteLine();
