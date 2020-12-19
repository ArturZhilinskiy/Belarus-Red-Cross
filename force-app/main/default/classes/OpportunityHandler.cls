public with sharing class OpportunityHandler {
    
    private static Map<String, Boolean> actionTypeToRunOnce = new Map<String, Boolean>();
    
    public static Boolean runOnce(String actionType) {
        Boolean runOnce = actionTypeToRunOnce.get(actionType);
        if (runOnce == null || runOnce == TRUE) {
            actionTypeToRunOnce.put(actionType, FALSE);
            return TRUE;
        }
        return FALSE;
    }
    
}