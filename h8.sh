#!/usr/bin/env bash

source awsdocs_general.sh

function get_instance_info {


    local INSTANCE_ID RESPONSE

    INSTANCE_ID=$1

    RESPONSE=$(aws ec2 describe-instances \
                   --query 'Reservations[*].Instances[*].[State.Name, InstanceType]' \
                   --filters Name=instance-id,Values="$INSTANCE_ID" \
                   --output text \
               )

    if [[ $? -ne 0 ]] || [[ -z "$RESPONSE" ]]; then
        return 1        
    fi

    EXISTING_STATE=$(echo "$RESPONSE" | cut -f 1 )
    EXISTING_TYPE=$(echo "$RESPONSE" | cut -f 2 )

    return 0        
}



function change_ec2_instance_type {

    function usage() (
        echo ""
        echo "This function changes the instance type of the specified instance."
        echo "Parameter:"
        echo "  -i  Specify the instance ID whose type you want to modify."
        echo "  -t  Specify the instance type to convert the instance to."
        echo "  -f  If the instance was originally running, this option prevents"
        echo "      the script from asking permission before stopping the instance."
        echo "  -r  Start instance after changing the type."
        echo "  -v  Enable verbose logging."
        echo ""
    )

    local FORCE RESTART REQUESTED_TYPE INSTANCE_ID VERBOSE OPTION RESPONSE ANSWER
    local OPTIND OPTARG 
    FORCE=false
    RESTART=false
    REQUESTED_TYPE=""
    INSTANCE_ID=""
    VERBOSE=false

    while getopts "i:t:frvh" OPTION; do
        case "${OPTION}"
        in
            i)  INSTANCE_ID="${OPTARG}";;
            t)  REQUESTED_TYPE="${OPTARG}";;
            f)  FORCE=true;;
            r)  RESTART=true;;
            v)  VERBOSE=true;;
            h)  usage; return 0;;
            \?) echo "Invalid parameter"; usage; return 1;;
        esac
    done

    if [[ -z "$INSTANCE_ID" ]]; then
        errecho "ERROR: You must provide an instance ID with the -i parameter."
        usage
        return 1
    fi

    if [[ -z "$REQUESTED_TYPE" ]]; then
        errecho "ERROR: You must provide an instance type with the -t parameter."
        usage
        return 1
    fi

    iecho "Parameters:\n"
    iecho "    Instance ID:   $INSTANCE_ID"
    iecho "    Requests type: $REQUESTED_TYPE"
    iecho "    Force stop:    $FORCE"
    iecho "    Restart:       $RESTART"
    iecho "    Verbose:       $VERBOSE"
    iecho ""

    iecho -n "Confirming that instance $INSTANCE_ID exists..."
    get_instance_info "$INSTANCE_ID"
    if [[ ${?} -ne 0 ]]; then
        errecho "ERROR: I can't find the instance \"$INSTANCE_ID\" in the current AWS account."
        return 1
    fi

    iecho "confirmed $INSTANCE_ID exists."
    iecho "      Current type: $EXISTING_TYPE"
    iecho "      Current state code: $EXISTING_STATE"

    if [[ "$EXISTING_TYPE" == "$REQUESTED_TYPE" ]]; then
        errecho "ERROR: Can't change instance type to the same type: $REQUESTED_TYPE."
        return 1
    fi

    if [[ "$EXISTING_STATE" == "running" ]]; then
        if [[ $FORCE == false ]]; then
            while true; do
                echo ""
                echo "The instance $INSTANCE_ID is currently running. It must be stopped to change the type."
                read -r -p "ARE YOU SURE YOU WANT TO STOP THE INSTANCE? (Y or N) " ANSWER
                case $ANSWER in
                    [yY]* )
                        break;;
                    [nN]* )
                        echo "Aborting."
                        exit;;
                    * )
                        echo "Please answer Y or N."
                        ;;
                esac
            done
        else
            iecho "Forcing stop of instance without prompt because of -f."
        fi

   
        iecho -n "Attempting to stop instance $INSTANCE_ID..."
        RESPONSE=$( aws ec2 stop-instances \
                        --instance-ids "$INSTANCE_ID" )

        if [[ ${?} -ne 0 ]]; then
            echo "ERROR - AWS reports that it's unable to stop instance $INSTANCE_ID.\n$RESPONSE"
            return 1
        fi
        iecho "request accepted."
    else
        iecho "Instance is not in running state, so not requesting a stop."
    fi;

    iecho "Waiting for $INSTANCE_ID to report 'stopped' state..."
    aws ec2 wait instance-stopped \
        --instance-ids "$INSTANCE_ID"
    if [[ ${?} -ne 0 ]]; then
        echo "\nERROR - AWS reports that Wait command failed.\n$RESPONSE"
        return 1
    fi
    iecho "stopped.\n"

    iecho "Attempting to change type from $EXISTING_TYPE to $REQUESTED_TYPE..."
    RESPONSE=$(aws ec2 modify-instance-attribute \
                   --instance-id "$INSTANCE_ID" \
                   --instance-type "{\"Value\":\"$REQUESTED_TYPE\"}"
              )
    if [[ ${?} -ne 0 ]]; then
        errecho "ERROR - AWS reports that it's unable to change the instance type for instance $INSTANCE_ID from $EXISTING_TYPE to $REQUESTED_TYPE.\n$RESPONSE"
        return 1
    fi
    iecho "changed.\n"

    if [[ "$RESTART" == "true" ]]; then

        iecho "Requesting to restart instance $INSTANCE_ID..."
        RESPONSE=$(aws ec2 start-instances \
                        --instance-ids "$INSTANCE_ID" \
                   )
        if [[ ${?} -ne 0 ]]; then
            errecho "ERROR - AWS reports that it's unable to restart instance $INSTANCE_ID.\n$RESPONSE"
            return 1
        fi
        iecho "started.\n"
        iecho "Waiting for instance $INSTANCE_ID to report 'running' state..."
        RESPONSE=$(aws ec2 wait instance-running \
                       --instance-ids "$INSTANCE_ID" )
        if [[ ${?} -ne 0 ]]; then
            errecho "ERROR - AWS reports that Wait command failed.\n$RESPONSE"
            return 1
        fi

        iecho "running.\n"

    else
        iecho "Restart was not requested with -r.\n"
    fi
}
