#!/bin/bash

time salt-run state.orch orch.highstate --state-output=mixed --log-level=quiet
