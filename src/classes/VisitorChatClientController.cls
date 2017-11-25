/************************************************************************
 * Author: Mangesh Honale honalemangesh@gmail.com
 * Developed on: 28 September 2016
 * Controller for page where site visitor puts in some information 
 * initiates chat.
 ************************************************************************/

public class VisitorChatClientController{
    //wrapper class to represent visitor
    public class Visitor{
        public String firstName { get; set; }
        public String lastName { get; set; }
        public String email { get; set; }
        public String companyName { get; set; }
    }
    
    public class Conversation{
        public Boolean isVisitor;
        public String message;
        public String ts;
    }
    
    public Chat_Conversation__c chatConv { get; set; }
    public String accessToken { get{
        List<Agent_Chat_Setup__c> setupList = Agent_Chat_Setup__c.getAll().values();
        if(!setupList.isEmpty() && !initiateChat){
            Agent_Chat_Setup__c setup = setupList.get(0);
            HttpResponse response = Utils.getAccessToken(setup);
            if(response.getStatusCode() == 200){
                // Parse JSON response to get access token.
                JSONParser parser = JSON.createParser(response.getBody());
                while (parser.nextToken() != null) {
                    if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && 
                    (parser.getText() == 'access_token')) {
                        // Get the value.
                        parser.nextToken();
                        initiateChat = true;
                        accessToken = parser.getText(); 
                        chatConv.Id = ApexPages.currentPage().getParameters().get('Id');
   
                    }
                }
            }
        }
        return accessToken;
    }
    set; }
    
    public Visitor visitor { get; set; }
    public String userSkill { get; set; }
    public String errorMsg {get; set;}
    public User sfdcAgent { get; set; }
    public Boolean msgDeliveryfail { get; set; }
    public Boolean initiateChat { get; set; }

    
    //constructor
    public VisitorChatClientController(){
        chatConv = new Chat_Conversation__c();
        visitor = new Visitor();
        msgDeliveryfail = false;
        initiateChat = false;
        
       
    }
    
    //returns list of skills
    public List<SelectOption> getSkills(){
        List<SelectOption> skillsList = new List<SelectOption>();
        skillsList.add(new SelectOption('', 'Select a topic'));
        
        //get the picklist entries from Skillset field on Agent Configuration object
        Schema.DescribeFieldResult skillset = Agent_Configuration__c.Skillset__c.getDescribe();
        
        for (Schema.PicklistEntry TypeItem: skillset.getPicklistValues()) {
            skillsList.add(new SelectOption(TypeItem.getValue(), TypeItem.getLabel()));
        } 
        
        return skillsList;
        
    }
    
    
    public pageReference initiateChat(){
    
        //check if user has provided all the information
        if(validateInputs()){
            
            //get available agent with selected skill
            String queryString = 'Select Id, Agent__c, Agent__r.Name from Agent_Configuration__c where Skillset__c includes (\'' + userSkill + '\') and Status__c =\'Available\' and Agent__c != null';
            List<Agent_Configuration__c> agentList = Database.Query(queryString);
            
            if(!agentList.isEmpty()){
                Agent_Configuration__c agentConfig = agentList.get(0);
                 chatConv.Agent__c = agentConfig.Agent__c;
                 sfdcAgent = [Select Name from User where Id =: agentConfig.Agent__c];
                //check for existing app setup
                List<Agent_Chat_Setup__c> setupList = Agent_Chat_Setup__c.getAll().values();
                if(!setupList.isEmpty()){
                    Agent_Chat_Setup__c setup = setupList.get(0);
                     if(!initiateChat){
                         //check if an email notification is to be sent to agent.
                         if(setup.Email_Notification__c){
                             
                             String subject = 'New Chat Request from ' + visitor.firstName + ' ' + visitor.lastName;
                             String body = 'Hello ' + agentConfig.Agent__r.Name + ',<br/><br/>' + visitor.firstName + ' ' + visitor.lastName + ' wants to discuss with you about ' + userSkill + '. Click <a href=\"' + 
                                         URL.getSalesforceBaseUrl().toExternalForm() + '/apex/AgentChatClient?Id=' + chatConv.Id + '\">here</a> to accept the request.' + 
                                         '<br/> <br/><i>You are receiving this email because your administrator has enabled email notifications for new chat requests.' + '</i><br/><br/>Thanks & Regards,<br/>Agent Chat';
                            Utils.sendEmail(subject, body, chatConv.Agent__c);
                         } 
                                     //look for existing contact
                        List<Contact> contactsList = [Select Id, Name from Contact where FirstName =: visitor.firstName and LastName =: visitor.lastName
                                                      and Email =: visitor.Email];
                        if(!contactsList.isEmpty()){
                            Contact con = contactsList.get(0);
                            chatConv.Contact__c = con.Id;
                        }else{
                            
                            //if contact not found then look for existing lead
                            List<Lead> leadsList = [Select Id, Name from Lead where FirstName =: visitor.firstName and LastName =: visitor.lastName
                                                      and Email =: visitor.Email];
                            Lead lead;                
                            if(!leadsList.isEmpty()){
                                lead = leadsList.get(0);
                            }else{
                                
                                //if existing lead not found then insert a new lead
                                lead = new Lead();
                                lead.FirstName = visitor.firstName;
                                lead.LastName = visitor.LastName;
                                lead.Email = visitor.Email;
                                lead.Company = visitor.companyName;
                                insert lead;
                            }
                            
                            chatConv.Lead__c = lead.Id;
                        }
                         upsert chatConv;
                         PageReference chatWindow = new PageReference('/apex/VisitorChatClient');
                         chatWindow.setRedirect(true);
                         chatWindow.getParameters().put('Id', chatConv.Id);
                         return chatWindow;
                     }else{
                     
                         errorMsg = 'Could not connect. Sorry for the inconvenience caused.';
                         displayMessage();
                         
                     }
        
                }
            }else{
                errorMsg = 'There is no one online to address your query about ' + userSkill + ' right now. Please wait for some time.';
                displayMessage();
            }
       
        }else{
            errorMsg = 'Please provide all the information to proceed.';
            displayMessage();
        }
         return null;
    }
    
    //valites user input data
    private boolean validateInputs(){
        if(visitor.firstName == null || visitor.firstName == '' || visitor.lastName == null || 
          visitor.lastName == '' || visitor.email == null || visitor.email == '' || userSkill == '' || 
          visitor.companyName == null || visitor.companyName == '' || userSkill == null || userSkill == ''){
            return false;
        }
        return true;
    }
    
    //method to display error messages on page.
     void displayMessage(){
         ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.Error, errorMsg);
         ApexPages.addMessage(myMsg); 
     }
    
    public void sendMessage(){
        if(chatConv.Message__c != null && chatConv.Message__c != ''){
            //save message to conversation
            Conversation conv = new Conversation();
            conv.isVisitor = true;
            conv.message = chatConv.Message__c;
            conv.ts = System.now().hour() + ':' + System.now().minute();
            
            chatConv.Conversation__c = JSON.serialize(conv);
            chatConv.Message__c = 'Visitor:# ' + chatConv.Message__c;
            
            try{
                upsert chatConv;
                msgDeliveryfail = false;
            }catch(DMLException ex){
                msgDeliveryfail = true;
                errorMsg = 'Failed to send the message. Please try again.';
                if(StatusCode.STRING_TOO_LONG == ex.getDmlType(0)){
                    errorMsg = 'Message too long. Maximum 240 characters allowed.';
                }

            }
            chatConv.Message__c = '';
        }
    }
}