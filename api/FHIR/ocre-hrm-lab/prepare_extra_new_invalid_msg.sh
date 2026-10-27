cd ~/health-integration-lab/api/FHIR/ocre-hrm-lab

sed 's/SYNTH-OCRE-0010/SYNTH-OCRE-0011/g' \
  examples/lab02/valid-0011.hl7 \
  > examples/lab02/valid-0012.hl7
