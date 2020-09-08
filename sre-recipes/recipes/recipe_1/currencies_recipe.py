# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# -*- coding: utf-8 -*-
"""
This module contains the implementation of recipe 1
"""

import logging
import subprocess
from recipe import Recipe


class CurrenciesRecipe(Recipe):
    """
    This class implements recipe 1, which purposefully
    introduces latency into the frontend service.
    """

    @staticmethod
    def _run_command(command):
        """Runs the given command and returns any output and error"""
        process = subprocess.Popen(command.split(), stdout=subprocess.PIPE)
        output, error = process.communicate()
        return output, error

    @staticmethod
    def _deploy_state(state):
        """
        Sets an environment variable CONVERT_CURRENCIES to given state
        and updates the state accordingly
        """
        state_str = str(state).lower()
        set_env_command = f"kubectl set env deployment/frontend CONVERT_CURRENCIES={state_str}"
        get_pod_command = """kubectl get pod -l app=frontend -o \
            jsonpath=\"{.items[0].metadata.name}\""""
        logging.info('Setting env variable: %s', set_env_command)
        logging.info('Getting pod: %s', get_pod_command)

        CurrenciesRecipe._run_command(set_env_command)
        service, error = CurrenciesRecipe._run_command(get_pod_command)
        service = service.decode("utf-8").replace('"', '')
        delete_pod_command = f"kubectl delete pod {service}"
        logging.info('Deleting pod: %s', delete_pod_command)
        CurrenciesRecipe._run_command(delete_pod_command)

    def break_service(self):
        """
        Rolls back the working version of the given service and deploys the
        broken version of the given service
        """
        print("Deploying broken service...")
        self._deploy_state(True)
        logging.info('Deployed broken service')

    def restore_service(self):
        """
        Rolls back the broken version of the given service and deploys the
        working version of the given service
        """
        print("Deploying working service...")
        self._deploy_state(False)
        logging.info('Deployed working service')

    @staticmethod
    def _get_user_input():
        """Prompts users for an answer"""
        answer = input('Your answer: ')
        return answer

    def _service_multiple_choice(self):
        """
        Displays a multiple choice quiz to the user about which service
        broke and prompts the user for an answer
        """
        print('Which service broke?')
        print('\t[a] ad service')
        print('\t[b] cart service')
        print('\t[c] checkout service')
        print('\t[d] currency service')
        print('\t[e] email service')
        print('\t[f] frontend service')
        print('\t[g] payment service')
        print('\t[h] product catalog service')
        print('\t[i] recommendation service')
        print('\t[j] redis')
        print('\t[k] shipping service')
        answer = self._get_user_input()
        return answer

    def _cause_multiple_choice(self):
        """
        Displays a multiple choice quiz to the user about the cause of
        the breakage and prompts the user for an answer
        """
        print('What caused the breakage?')
        print('\t[a] failed connections to other services')
        print('\t[b] high memory usage')
        print('\t[c] high latency')
        print('\t[d] dropped requests')
        answer = self._get_user_input()
        return answer

    def _verify_broken_service(self):
        """Verifies the user found which service broke"""
        answer = self._service_multiple_choice()
        while answer not in ('f', 'F'):
            print('Incorrect. Please try again.')
            answer = self._get_user_input()
        print('Correct! The frontend service is broken.')

    def _verify_broken_cause(self):
        """Verifies the user found the root cause of the breakage"""
        answer = self._cause_multiple_choice()
        while answer not in ('c', 'C'):
            print('Incorrect. Please try again.')
            answer = self._get_user_input()
        print('Correct! High latency caused the breakage.')

    def verify(self):
        """Verifies the user found the root cause of the broken service"""
        print('This is a multiple choice quiz to verify that you\'ve')
        print('found the root cause of the break')
        self._verify_broken_service()
        self._verify_broken_cause()
        print('Good job! You have correctly identified which service broke')
        print('and what caused it to break!')
