#!/usr/bin/env bash

# Bash Operator agent to run bash commands and get the output

#settings
API_URL=  https://api.openai.com/v1/models
MODEL="gpt-4o-mini"
AGENT_NAME="Sentinel-1"
SYSTEM_PROMPT="you are bash operator agent: "

#gather system snapshort for smarter responses
get_context() {
    printf "OS: %s | Disk: %s | users: %s \
        "$(uname -a)" \
        "$(df -h /" | tail -1") \
        "$(who | wc -l)"
    }
# Ask the LLM for Runnable Bash Command
    ask_agent() {
        local task="$1"
        local context="$(get_context)"
        
        response=$(curl -s $API_URL" \
            -H "cotent-Type: application/json \
            -H "Authorization: Bearer $API_Key" \
            -d "{
                \"model\": \"$MODEL_NAME\",
                \"messages\": [
                    {\"role\": \"system\", \"content\": \"$SYSTEM_PROMPT\"},
                    {\"role\": \"user\", \"content\": \"$task\"}
                ]
                }")
         echo \$response | jq -r '.choices[0].message.content'
        
    }
    #infinite helper Loop 
    run_agent() {
        echo 
        echo "==============="
        echo "Bash Operator Agent"
        echo "==============="
        echo "Type 'exit' to quit"
        echo "==============="
        while true; do
            read -rp "ASK the AI to do Something(or 'exit' to quit) " task
             [[ "$task" == "exit" ]] && break
             cmd="$(ask_agent "$task")"
             echo -e "\nSuggested command: \003[1;33m$cmd\003[0m"

             read -rp "Execute?(y/n): " -n 1 REPLY
             echo 
             if [[ "$REPLY" == "Yy" ]]; then
                echo -e "\nrunning ...."
                eval "$cmd"
                echo
            else
                echo "Skipped."
            fi 
            echo 
        done 
        echo "Agent terminated. "
    }
    # Run the agent
    run_agent




### After complete this code. i have conclude the reviews of cursor IDE
## cursor gives excellent suggestions and really helpfull with code completion.
## but sometimes the constant hints can distract me from the main logic, so i prefer turning them
# down when i need to focus. 

