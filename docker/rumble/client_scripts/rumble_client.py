"""
Author:      Ceyhun Uzunoglu <ceyhunuzngl AT gmail dot com>
Description: Client to run jsoniq queries in rumble server.
"""

# system modules
import os
import sys
import json
import argparse

# third party libs
import requests

class OptionParser():
    def __init__(self):
        "User based option parser"
        self.parser = argparse.ArgumentParser(prog='PROG')
        self.parser.add_argument("--data", action="store",
            dest="data", default="", help="Input file or query")
        self.parser.add_argument("--output", action="store",
            dest="output", default=None, help="Output file")
        self.parser.add_argument("--server", action="store",
            # Max output size is 1.000.000.000 records
            dest="server", default="http://test-cluster-jnbxujghdusq-node-0.cern.ch/jsoniq?materialization-cap=1000000000", help="Rumble server")


def handle_output_file(output_file):
    # Accepts both given full path of file or only file name which will be created in current directory.
    if os.path.isdir(os.path.abspath(os.path.join(output_file, os.pardir))):
        return output_file
    else:
        print("Given output file path is not exist or not reachable:", output_file)
        print("Writing to default path: ", os.path.join(os.getcwd(), "rumble_output.txt"))
        return os.path.join(os.getcwd(), "rumble_output.txt")

def rumble(server, data, output=None):
    response = json.loads(requests.post(server, data=data).text)
    # print(json.dumps(response.json()))
    if 'warning' in response:
        print(json.dumps(response['warning']))
    if 'values' in response:
        if output:
            output_file = handle_output_file(output)
            try:
                with open(output_file, "w+") as f:
                    f.write(json.dumps(response))
                    return "Successfully written to: " + str(os.path.join(os.getcwd(), output))
            except Exception as e:
                print("Could not write to file:", output_file)
                print(e)
        else:
            for e in response['values']:
                return json.dumps(e)
    elif 'error-message' in response:
        return response['error-message']
    else:
        return response

def main():
    "Main function"
    optmgr  = OptionParser()
    opts = optmgr.parser.parse_args()
    # Get query as data
    if os.path.exists(opts.data):
        data = open(opts.data).read()
    else:
        data = opts.data
    # Get output path as output
    if opts.output:
        output = opts.output
    else:
        print("Output path is not given or path is not exist. Result will be stdout!")
        output = None
    print("<Input Query>:")
    print(data)
    resp = rumble(opts.server, data, output)
    if resp:
        print("<Rumble Response Values>")
        print(resp)

if __name__ == '__main__':
    main()
