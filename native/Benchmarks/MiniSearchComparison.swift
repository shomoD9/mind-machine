/* Same-corpus MiniSearch comparison compiled standalone by native CI. It loads
 only an integrity-verified MIT benchmark bundle, never the user's vault. The
 query corpus/options mirror SearchPerformanceTests and VaultIntegrityProbe. */
import Foundation
import JavaScriptCore
import Darwin

@main struct MiniSearchComparison {
    static func main() throws {
        let start = DispatchTime.now().uptimeNanoseconds
        let context = JSContext()!
        context.evaluateScript(try String(contentsOfFile: CommandLine.arguments[1]))
        context.evaluateScript("""
        var documents = [];
        var nouns = ['telescope','birthday','passport','recipe','meeting','garden','invoice','holiday','bicycle','library'];
        for (var i=0;i<10000;i++) documents.push({id:i,text:nouns[i%10]+' project '+i+' remember the original plan for Mira with reference code item'+i+' and a useful link https://example.com/'+i});
        var engine = new MiniSearch({fields:['text'],storeFields:['text'],searchOptions:{prefix:true,fuzzy:0.2,combineWith:'AND'}});
        engine.addAll(documents);
        documents = null;
        function queryTop(q) { return engine.search(q).slice(0,30).map(function(r){ return r.text; }); }
        """)
        if let exception = context.exception { throw NSError(domain: "MiniSearch", code:1, userInfo:[NSLocalizedDescriptionKey:exception.toString() ?? "JS failure"]) }
        JSGarbageCollect(context.jsGlobalContextRef)
        let queries = ["teles", "telescpoe", "passport", "birthd", "gardne", "item9876", "recipe project", "nohitsxyz"]
        let cold = Double(DispatchTime.now().uptimeNanoseconds-start)/1_000_000
        var timings: [Double] = []
        let function = context.objectForKeyedSubscript("queryTop")!
        for query in queries {
            let count = function.call(withArguments: [query])!.toArray()!.count
            print("MM_MINISEARCH_MATCH query=\(query) count=\(count)")
        }
        for i in 0..<240 {
            let begin = DispatchTime.now().uptimeNanoseconds
            _ = function.call(withArguments: [queries[i % queries.count]])!.toArray()
            timings.append(Double(DispatchTime.now().uptimeNanoseconds-begin)/1_000_000)
        }
        if let exception = context.exception { throw NSError(domain:"MiniSearch", code:2,userInfo:[NSLocalizedDescriptionKey:exception.toString() ?? "JS failure"]) }
        var usage = rusage(); getrusage(RUSAGE_SELF,&usage)
        print("MM_MINISEARCH notes=10000 query_p95_ms=\(timings.sorted()[227]) startup_and_index_ms=\(cold) peak_rss_mib=\(Double(usage.ru_maxrss)/1048576)")
    }
}
