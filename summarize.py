import json
import os
import sys

if __name__ == "__main__":
    result = {}
    for f_name in os.listdir(sys.argv[1]):
        if not f_name.endswith(".json"):
            continue
        instance_type = f_name.strip(".json").replace("_", ".")
        result[instance_type] = {}
        with open(os.path.join(sys.argv[1], f_name), "r") as f:
            data = json.load(f)
            for job in data["jobs"]:
                if job["jobname"] == "Write_PPS_Testing":
                    result[instance_type]["throughput"] = job["write"]["bw"]/1024
                if job["jobname"] == "Rand_Write_Testing":
                    result[instance_type]["iops"] = job["write"]["iops"]
    instance_types = sorted(result.keys())
    for instance_type in instance_types:
        print(f"{instance_type}: {result[instance_type]['throughput']:0.1f} MiB/s, {result[instance_type]['iops']:0.1f} IOPS")
