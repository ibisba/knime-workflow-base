#!/bin/bash
args=()

if [ "$1" == "--help" ]; then
  echo 'Workflow variables:'
  echo 'Name Type'
  cat $HOME/meta
else
  for var in "$@"
  do
      # Extract the variable name
      name=$(echo $var | awk -F '=' '{print $1}')
      # Extract the type
      value=$(echo $var | awk -F '=' '{print $2}')
      # Get the type from the meta file
      type=$(cat $HOME/meta | grep $name | awk -F ' ' '{print $2}')
      # Add argument to the array
      args=("${args[@]}" "-workflow.variable=$name,\"$value\",$type")
      #\\\"
  done

  echo ${args[@]}

  # Call KNIME with the arguments
  $KNIME_DIR/knime -configuration $HOME/configuration -data $HOME -user $HOME -nosplash -nosave -application org.knime.product.KNIME_BATCH_APPLICATION \
    -workflowDir="/payload/workflow" \
    "${args[@]}"
fi
