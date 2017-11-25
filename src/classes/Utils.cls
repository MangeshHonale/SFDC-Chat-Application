/**************************************************************
 * Author: Mangesh Honale honalemangesh@gmail.com
 * Developed on: 27 September 2016
 * Contains utility methods used across Agent Chat application.
 **************************************************************/
 
 
 public class Utils{
     
     //send an email to given address with given subject and body
     public static void sendEmail(String subject, String body, Id targetObjectId){
         try{
              Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    
              // Set list of people who should get the email
              
              mail.setTargetObjectId(targetObjectId);
              
              Organization org = [Select Name from Organization limit 1];
              
              mail.setSenderDisplayName(org.Name + ' - Agent Chat');
            
              //Set email contents
              mail.setSubject(subject);
              mail.setHtmlBody(body);
              mail.setSaveAsActivity(false);
              Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {mail};
              Messaging.sendEmail(messages);  
 
          }catch(Exception ex){
         
         }
     }
     
     //send given http request
     public static HttpResponse sendHttpRequest(String reqEndpoint, String method, String body){
       
             
             Http httpProtocol = new Http();
             
             // Create HTTP request to send.
             HttpRequest request = new HttpRequest();
             
             //set request endpoint
             request.setEndPoint(reqEndpoint);
             
             //set request method
             request.setMethod(method);      
             
             // Send the HTTP request and get the response.
             // The response is in JSON format.
             return httpProtocol.send(request);       
             
             
 

     }
     
     //requests access token with given username, password, connected app client id and client secret.
     public static HttpResponse getAccessToken(Agent_Chat_Setup__c config){
         
         try{
             String endpoint = 'https://login.salesforce.com/services/oauth2/token';  //endpoint for production or developer org login
                     
             //if the current org is sandbox then endpoint will be of sandbox login
             Organization org = [Select IsSandbox from Organization limit 1];
             if(org.IsSandbox){
                 endpoint = 'https://test.salesforce.com/services/oauth2/token';
             }
             
             // Set the endpoint URL.
             String reqEndpoint = endpoint + '?grant_type=password&' + 'client_id=' + config.Client_Id__c + '&client_secret=' + config.Client_Secret__c + '&username=' + config.Salesforce_Username__c + '&password=' + config.Salesforce_Password__c;
            
             return Utils.sendHttpRequest(reqEndpoint, 'POST', null);
         }catch(Exception ex){
             throw new ApplicationException('Request could not be processed. Please try again.');
         }        
     
     }
     
     
     public class ApplicationException extends Exception {}
 }