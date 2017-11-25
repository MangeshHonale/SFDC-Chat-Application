public class AgentChatClientController{
    
    public Chat_Conversation__c chatConv { get; set; }
    public String message { get; set; }
    
    public AgentChatClientController(){
        Id id = apexpages.currentpage().getparameters().get('id');
        if(id != null){
            List<Chat_Conversation__c> chatConvList = [Select Id, Contact__c, Conversation__c, Lead__c, Message__c, Status__c, Visitor_Name__c
                                                       from Chat_Conversation__c where Id =: id];
            if(!chatConvList.isEmpty()){
                chatConv = chatConvList.get(0);
                message = chatConv.Message__c;
                if(message != null && message != '' && message.contains('Visitor:#'))
                    message = message.replace('Visitor:#', chatConv.Visitor_Name__c + ': ');
            }    
        }

    }
    
    public void sendMessage(){
        
        if(chatConv != null && chatConv.Status__c != 'In Progress')
            chatConv.Status__c = 'In Progress';
        if(chatConv.Message__c != null && chatConv.Message__c != '')
            update chatConv;
    }
    
    

}