#!/bin/bash
# Version 4.0
# - Code is better written as 3.0
# - check if file exists

args=()
workflow=$1
declare -i multi_wrk=0
declare -i execute=1

if [ "$workflow" = "--vars" ]; then
    echo "Workflow variables needed for executing the workflows:"
    echo "-----------------------------------------------------"
    while IFS=  read -r -d $'\0'; do
      echo "$(dirname ${REPLY#./workflow/})"
      echo -e 'Name\tType\tDefault Value'
      cat "$REPLY" | tr ':' '\t'
      echo "========"
    done < <(find "/payload/workflow" -name dockermeta.knime -print0)
    execute=0
elif [ "$workflow" = "--info" ]; then
    echo "Workflows:"
    echo "-----------------------------------------------------"
    while IFS=  read -r -d $'\0'; do
      echo "$(dirname ${REPLY#./workflow/})"
    done < <(find "/payload/workflow" -name dockermeta.knime -print0)
    echo "-----------------------------------------------------"
    echo "Installed features:"
    echo "-----------------------------------------------------"
    cat features
    execute=0
elif [ "$workflow" = "--help" ]; then
    echo "Help:"
    echo "To run the image and mount a folder in the container:"
    echo "docker run -v <local_folder>:<container_folder> <image_name> <workflow_path> <workflow_variable_name>=<value>"
    echo "Eg: docker run -v /User/MyUser/Documents/Data:/data myworkflowGroup mySubGroup/myworkflow input_file=test.csv"
    echo ""
    echo "To list the workflows' variables:"
    echo "docker run -rm <image_name> --vars"
    echo ""
    echo "To list contained workflows and installed features:"
    echo "docker run -rm <image_name> --info"
    execute=0
fi

n=$(find /payload/workflow -name "dockermeta.knime" |wc -l)

#check for amount of workspace
if [ $n == 0 ]; then
 echo "NON WORKSPACE FOUND. Check if the workflow directory is correctly specified"
elif [ $n == 1 ]; then
 wrk="${@:1}"
 workflow=""
 echo "One workflow found."
elif [ $n -gt 1 ]; then
 wrk="${@:2}"
 multi_wrk=1 
 echo "Multiple workflows found."
 # Check if file exists
 if [[ $execute == 1 && ! -f "/payload/workflow/$workflow/dockermeta.knime" ]]
 then
    >&2 echo "Workflow not found. Check the name of the workflow."
    n=0
 fi
fi


if [[ $execute == 1 && $n -gt 0 ]] ; then
    for var in $wrk
    do
	  # Extract the variable name
	  name=$(echo $var | awk -F '=' '{print $1}')
	  # Extract the type
	  value=$(echo $var | awk -F '=' '{print $2}')
	  # Get the type from the meta file checking if its a single or a multiple workflow
	  if [ $multi_wrk == 1 ] ; then
	   type=$(cat /payload/workflow/$workflow/dockermeta.knime | grep $name | awk -F ':' '{print $2}')
          else
	   type=$(cat /payload/workflow/dockermeta.knime | grep $name | awk -F ':' '{print $2}')	
	  fi
	  # Add argument to the array
	  args=("${args[@]}" "-workflow.variable=$name,\"$value\",$type")
	  #\\\"
    done
    # Call KNIME with the arguments
    WORKDIR="${pwd}"
    $KNIME_DIR/knime -configuration $WORKDIR/configuration -data $WORKDIR -user $WORKDIR -nosplash -nosave -application org.knime.product.KNIME_BATCH_APPLICATION \
      -workflowDir="/payload/workflow/$workflow" \
      "${args[@]}"
fi
