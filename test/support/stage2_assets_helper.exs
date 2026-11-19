# Complete; do not change.
for file <- ["naive_reference_helper.exs", "stage2_helper.exs", "public_contract_helper.exs"] do
  Code.require_file(Path.expand(file, __DIR__))
end
