for file in \
  examples/synthetic-oru.hl7 \
  examples/lab02/wrong-physician.hl7 \
  examples/lab02/valid-*.hl7
do
  if [ -f "$file" ]; then
    echo "Sending $file"

    docker run --rm \
      --network integration-lab \
      -v "$PWD/examples:/samples:ro" \
      python:3.12-alpine \
      python /samples/send-mllp.py \
        --host mirth452 \
        --port 2580 \
        --file "/samples/${file#examples/}"
  fi
done
