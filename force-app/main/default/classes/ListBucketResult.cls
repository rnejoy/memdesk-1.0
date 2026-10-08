public class ListBucketResult {
    private Dom.Document doc;
    private Dom.XmlNode rootNode;
    private static string ns = 'http://s3.amazonaws.com/doc/2006-03-01/';
    
    public List<string> Keys { get { return GetKeys(); } set; }
    
    public ListBucketResult(string XMLString) {
        doc = new Dom.Document();
        doc.load(XMLString);
        
        rootNode = doc.getRootElement();  
    }
    
    private List<string> GetKeys() {
        List<string> keyList = new List<string>();
        
        for(Dom.XmlNode node : rootNode.getChildElements()) {
            if(node.getName() == 'Contents') {
                string nodeValue = GetNodeText(node, 'Key');
                string decodedValue = nodeValue.replace('&amp;', '%26');
                keyList.add(decodedValue);
            }
        }
        
        return keyList;
    }
    
    private string GetNodeText(Dom.XmlNode CurrentNode, string NodeName) {
        return CurrentNode.getChildElement(NodeName, ns).getText();
    }
    
}