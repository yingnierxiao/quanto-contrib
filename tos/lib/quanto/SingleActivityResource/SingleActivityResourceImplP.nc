#include "activity.h"
#include "QuantoResources.h"

/* Provides a parameterized set of SingleActivityResource interfaces.
   The parameterization MUST be done on ids generated by
   the NEW_QUANTO_RESOURCE_ID macro.
*/

module SingleActivityResourceC {
    provides {
        interface SingleActivityResource[uint8_t res_id];
        interface SingleActivityResourceTrack[uint8_t res_id];
        interface Init;
    }
    uses {
        interface ActivityType;
    }
}

implementation {
    enum { NUM_RES = uniqueCount(QUANTO_RESOURCE_IDS) }; 
    act_t m_context[NUM_RES]; 
    act_t act_local_unknown;
    act_t act_local_idle;
    act_t act_local;

    /* Set the context of all resources to unknown context and
     * this node's id */
    command error_t Init.init() {
        int i;

        act_local_unknown = mk_act_local(QUANTO_ACTIVITY(UNKNOWN));
        act_local_idle = mk_act_local(QUANTO_ACTIVITY(IDLE));
        act_local = mk_act_local(0); //this is here so that changes in IDLE don't cause bugs

        for (i = 0; i < NUM_RES; i++) {
            m_context[i] = act_local_idle;
        }
        return SUCCESS;
    }

    async inline command act_t SingleContext.get[uint8_t res_id]() {
        atomic return m_context[res_id];
    }

    async inline command void SingleContext.set[uint8_t res_id](act_t n) {
        act_t old;
        atomic {
                old = m_context[res_id];
                m_context[res_id] = n;
        } 
        if (n != old)
            signal SingleContextTrack.changed[res_id](n);
    }

    async inline command void SingleContext.setLocal[uint8_t res_id](act_type_t a) {
        call SingleContext.set[res_id](mk_act_local(a));
    }

    async inline command void 
    SingleContext.bind[uint8_t res_id](act_t n) {
        act_t old;
        atomic {
                old = m_context[res_id];
                m_context[res_id] = n;
        } 
        if (n != old)
            signal SingleContextTrack.bound[res_id](n);
    }


    async inline command act_t 
    SingleContext.enterInterrupt[uint8_t res_id](act_t n) 
    {
        act_t old;
        n = act_local | (n & ACT_TYPE_MASK);
        atomic {
            old = m_context[res_id];
            m_context[res_id] = n;
        }
        signal SingleContextTrack.enteredInterrupt[res_id](n);
        return old;
    }

    async inline command void 
    SingleContext.exitInterrupt[uint8_t res_id](act_t restore_ctx) 
    {
        act_t old;
        if (restore_ctx == act_local_idle)
            return;
        atomic {
            old = m_context[res_id];
            m_context[res_id] = restore_ctx;
        }
        signal SingleContextTrack.exitedInterrupt[res_id](restore_ctx);   
    }

    async inline command void 
    SingleContext.exitInterruptIdle[uint8_t res_id]() 
    {
        act_t old;
        atomic {
            old = m_context[res_id];
            m_context[res_id] = act_local_idle;
        }
        signal SingleContextTrack.exitedInterrupt[res_id](act_local_idle);   
    }


    
    async inline command void  
    SingleContext.setUnknown[uint8_t res_id]() 
    {
        call SingleContext.set[res_id](act_local_unknown);
    }

    async inline command void  
    SingleContext.setIdle[uint8_t res_id]() 
    {
        call SingleContext.set[res_id](act_local_idle);
    }
    
    async inline command void  
    SingleContext.setInvalid[uint8_t res_id]() 
    {
        call SingleContext.set[res_id](ACT_INVALID);
    }

    async inline command bool  
    SingleContext.isValid[uint8_t res_id]()
    {
        return call ActivityType.isValid(&m_context[res_id]);
    }

    default async event void 
    SingleContextTrack.changed[uint8_t res_id](act_t newContext)
    {
    }

    default async event void
    SingleContextTrack.bound[uint8_t res_id](act_t newContext) {
    }

    default async event void 
    SingleContextTrack.enteredInterrupt[uint8_t res_id](act_t newContext) {
    }

    default async event void 
    SingleContextTrack.exitedInterrupt[uint8_t res_id](act_t newContext) {
    }
    

}
