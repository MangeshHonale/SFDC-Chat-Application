/*************************************************
 * Author: Mangesh Honale honalemangesh@gmail.com
 * Develope on: 11 September 2016
 * Agent Chat application set up page controller
 ************************************************/
 
 public class AgentChatSetupController{
 
     public Agent_Chat_Setup__c setup { get; set; } //set up configuration instance
     public String message { get; set; } //success and error messages to be displayed
     
     //constructor
     public AgentChatSetupController(){
         
         //retrieve existing set up, if there is any
         List<Agent_Chat_Setup__c> setupList = Agent_Chat_Setup__c.getAll().values();
         if(!setupList.isEmpty()){
             
             setup = setupList.get(0);

         }
         else{
             setup = new Agent_Chat_Setup__c();
             setup.name = 'Agent Chat Setup';
         }
     }
     
     //called from "Test Connection" button on page. Verifies connection credentials and shows appropriate message.
     public void testConnection(){
         if(validate()){
             try{
                 
                 //verifies the credentials by requesting an access token
                 verifyCredentials();
                 
             }catch(Utils.ApplicationException ex){
                 message = ex.getMessage();
                 displayMessage(ApexPages.severity.Error);
             }
             catch(Exception ex){
                 message = 'Something went wrong. Please try again.';
                 displayMessage(ApexPages.severity.Error);
             }
         }

     }
     
     //requests an access token. Returns true after receiving access token else false
     Boolean verifyCredentials(){
         
            
            
         HttpResponse response = Utils.getAccessToken(setup);

        
         if(response.getStatusCode() == 200){
         
             //show connection success message
             message = 'Connection tested successfully.';
             displayMessage(ApexPages.severity.CONFIRM);
             return true;
         }else{
         
             // Parse JSON response to get error message.
             JSONParser parser = JSON.createParser(response.getBody());
             system.debug('Response: ' + response.getBody());
             String errMsg = '';
             while (parser.nextToken() != null) {
                 if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && 
                     (parser.getText() == 'error_description')) {
                     
                     //show error message
                     parser.nextToken();
                     errMsg = parser.getText();
                     break;
                 }
             }
             
             message = 'Connection failed. ' + errMsg;
             displayMessage(ApexPages.severity.Error);
             
         }
         
         return false;
     }
     
     //returns list of users for selection of substitute agent
     public List<SelectOption> getUsersList(){
         List<SelectOption> userSelectList = new List<SelectOption>();
         
         userSelectList.add(new SelectOption('', 'Select Substitute Agent'));
         List<User> usersList = [Select Id, Name from User];
         if(!usersList.isEmpty()){
             for(User u : usersList){
                 userSelectList.add(new SelectOption(u.Id, u.Name));
             }
         }
         
         return userSelectList;
     }
     
     //method to display success or error messages on page. Accepts message type.
     void displayMessage(ApexPages.Severity messageType){
         ApexPages.Message myMsg = new ApexPages.Message(messageType, message);
         ApexPages.addMessage(myMsg); 
     }
     
     //called from "Save" button on page to save setup
     public void saveSetup(){
         try{
             if(validate()){
                 //if all the required information has been filled out then test the connection.
                 if(verifyCredentials()){
                     
                     //save the setup
                     upsert setup;
                     message = 'Your Changes have been saved.';
                     displayMessage(ApexPages.severity.CONFIRM);
                 }
                                
             }else{
                 displayMessage(ApexPages.severity.Error);
             }

         }catch(Exception ex){
             message = 'Something went wrong. Please try again.';
             displayMessage(ApexPages.severity.Error);
         }
     }
    
    //called from "Cancel" button on page. Redirects to home page 
    public PageReference cancel(){
        return new PageReference('/');
    }
    
    Boolean validate(){
        return true;
        //validate Salesforce username
        if(setup.Salesforce_Username__c == null || setup.Salesforce_Username__c == ''){
            message = 'Please provide Salesforce username of an user.';
            return false;
        }
        
        //validate Salesforce password and token        
        if(setup.Salesforce_Password__c == null || setup.Salesforce_Password__c == ''){
            message = 'Please provide Salesforce password and security token of an user.';
            return false;
        }
        
        //validate connected app client id
        if(setup.Client_Id__c == null || setup.Client_Id__c == ''){
            message = 'Please provide connected app client id.';
            return false;
        }
        
        //validate connected app client secret
        if(setup.Client_Secret__c == null || setup.Client_Secret__c == ''){
            message = 'Please provide connected app client secret.';
            return false;
        }
        
        //if all ok then return true;
        return true;
    }
 }