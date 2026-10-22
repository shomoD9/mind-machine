/* Isolated MiniSearch 7.1.0 native-host/latency probe, run during reuse research.
 It loads a caller-supplied, integrity-verified upstream UMD bundle into Apple's
 JavaScriptCore. No app target imports this file; no vault, network or OS
 permission is accessed. The report records setup, corpus and platform limits. */
import Foundation
import JavaScriptCore

@main struct MiniSearchProbe {
    static func main() throws {
        guard CommandLine.arguments.count >= 2 else {
            print("Usage: MiniSearchProbe /path/to/verified/index.js [capture-count]")
            return
        }
        // Runtime startup is measured separately from index construction and queries.
        let count = Int(CommandLine.arguments.dropFirst(2).first ?? "10000") ?? 10000
        guard count >= 44, count <= 100000 else { throw ProbeFailure.invalidCorpus }
        let startup = ContinuousClock.now
        guard let context = JSContext() else { throw ProbeFailure.runtimeUnavailable }
        context.evaluateScript(try String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8))
        try check(context)
        print("engine=MiniSearch 7.1.0, runtime=JavaScriptCore, captures=\(count), startup=\(startup.duration(to: .now))")
        // Synthetic varied notes give literal known matches and a no-overlap
        // paraphrase that this lexical-only engine is expected not to recover.
        let fixture = """
        var documents = [];
        var examples = [
          'Build a wooden shelf. Save the design link and buy screws.',
          'Research database replicas and protect encrypted backups.',
          'Book a train journey. Pack a notebook and charger.',
          'Write a reflective essay about learning through experiments.',
          'Read a gardening book and water the plants.'
        ];
        for (var i = 0; i < \(count); i++) documents.push({id:i, title:'Note '+i, text:examples[i % examples.length]});
        documents[42] = {id:42, title:'Birthday present for mum', text:'A ceramic mug from the museum shop.'};
        documents[43] = {id:43, title:'चाय की दुकान', text:'एक छोटी दुकान और किताबें'};
        var engine = new MiniSearch({fields:['title','text'], storeFields:['title'],
          searchOptions:{boost:{title:2},prefix:true,fuzzy:0.2,combineWith:'AND'}});
        engine.addAll(documents);
        function queryTop(q) { return engine.search(q).slice(0,10).map(function(r){return r.id}); }
        """
        let indexStart = ContinuousClock.now
        context.evaluateScript(fixture)
        try check(context)
        print("index_build=\(indexStart.duration(to: .now))")
        // Record independent expected identifiers through the library's public API.
        // The numbers measure this bridge and lexical path only, with no UI or embeddings.
        let queries: [(String, Int?)] = [("birthday",42),("birthd",42),("bithday",42),("चाय",43),("maternal celebration",nil),("train",nil)]
        for (query, expected) in queries {
            var samples: [Double] = []
            var returned: [Int] = []
            for _ in 0..<50 {
                let start = ContinuousClock.now
                let value = context.objectForKeyedSubscript("queryTop")?.call(withArguments: [query])
                returned = value?.toArray()?.compactMap { ($0 as? NSNumber)?.intValue } ?? []
                let duration = start.duration(to: .now).components
                samples.append(Double(duration.seconds) * 1000 + Double(duration.attoseconds) / 1e15)
            }
            try check(context)
            if let expected, returned.first != expected { throw ProbeFailure.wrongResult(query) }
            if query == "maternal celebration", !returned.isEmpty { throw ProbeFailure.wrongResult(query) }
            samples.sort()
            print(String(format:"query=%@, p50_ms=%.3f, p95_ms=%.3f, max_ms=%.3f, top_ids=%@", query,
                         samples[24], samples[47], samples[49], String(describing: returned)))
        }
        // Serialization/reload and a deletion smoke check establish only
        // that the native bridge can call these upstream operations successfully.
        context.evaluateScript("""
        var serialized = JSON.stringify(engine);
        var reloaded = MiniSearch.loadJSON(serialized,{fields:['title','text'],storeFields:['title']});
        var persistedMatch = reloaded.search('birthday')[0].id;
        reloaded.discard(42);
        var deletedAbsent = reloaded.search('birthday').every(function(result){return result.id !== 42;});
        """)
        try check(context)
        guard context.objectForKeyedSubscript("persistedMatch")?.toInt32() == 42,
              context.objectForKeyedSubscript("deletedAbsent")?.toBool() == true else { throw ProbeFailure.persistence }
        print("serialize_reload=passed, discard=passed, serialized_index_bytes=\(context.objectForKeyedSubscript("serialized")?.toString()?.utf8.count ?? 0)")
    }

    // JavaScript errors are surfaced explicitly rather than counted as empty matches.
    private static func check(_ context: JSContext) throws {
        if let exception = context.exception { throw ProbeFailure.script(exception.toString() ?? "Unknown JavaScript error") }
    }
    private enum ProbeFailure: Error {
        case runtimeUnavailable, invalidCorpus, wrongResult(String), persistence, script(String)
    }
}
