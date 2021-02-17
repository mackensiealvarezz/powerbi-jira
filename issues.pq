/*
Author: Mackensie Alvarez
github: mackensiealvarezz

Script also supports custom fields and removal of duplicate fields
*/

let 
    //Project key - change this to your project key
    Project = "TEST",
    
    //Change this to the url of your jira
    BaseUrl = "https://jiraurl.com/rest/api",
    
    //Items per request, Recommand to stay between 50-500
    JiraIDPerPage = 500,

    GetJson = (queries) =>
        let 
            RawData = Web.Contents(
                        BaseUrl,
                        [
                        RelativePath="2/search",
                        Query=queries,
                        Timeout=#duration(0, 2, 30, 30)
                        ]),
            Json    = Json.Document(RawData)
        in  Json,
 
    GetJiraIDCount = () =>
            let  Json  = GetJson([jql="project="& Text.From(Project),maxResults="0", expand="names"]),
            Count = Json[#"total"]
        in  Count,
 
    GetPage = (Index) =>
        let Json  = GetJson([jql="project="& Text.From(Project), startAt=Text.From(Index * JiraIDPerPage), maxResults=Text.From(JiraIDPerPage), expand="names"]),
            Value = Json
        in  Value,



    //Find the total number of tickets
    TotalNumberOfIssues = List.Max({ JiraIDPerPage, GetJiraIDCount() }),
    
    //Number of pages -  this is how many times we will request data
    PageCount   = Number.RoundUp(TotalNumberOfIssues / JiraIDPerPage),

    PageIndices = { 0 .. PageCount - 1 },
    Pages       = List.Transform(PageIndices, each GetPage(_)[#"issues"]),
    JiraID    = List.Union(Pages),
    
    Table       = Table.FromList(JiraID, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
     // If you have fields that have the same label, remove the duplicates by putting the field name in the list
    FieldNames =  Record.RemoveFields(GetPage(0)[#"names"], {"customfield_10913"}),
    FieldNamesTable = Record.ToTable(FieldNames),
    FieldKeysList = FieldNamesTable[#"Name"],
    FieldValuesList = FieldNamesTable[#"Value"],
    #"Expanded Column1" = Table.ExpandRecordColumn(Table, "Column1", {"id", "key", "fields"}, {"Column1.id", "Column1.key", "Column1.fields"}),
    #"Expanded Column1.fields" = Table.ExpandRecordColumn(#"Expanded Column1", "Column1.fields", FieldKeysList, FieldValuesList)
in
    #"Expanded Column1.fields"
