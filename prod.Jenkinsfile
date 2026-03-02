pipeline { 
    agent any 
     environment {
        STACK_NAME = "todo-list-aws-production"
    }
    stages { 
        stage('Checkout Code') { 
            steps { 
              git(
                branch: 'master',
                url: 'https://github.com/ELVIS1230/todo-list-aws.git',
                credentialsId: 'GITHUB1.4'
              )
            } 
        } 
        stage('Deploy') {
           steps {
                script{
                    sh """
                      set -e
                          REGION="us-east-1"
                          echo "===== AWS Identity ====="
                          aws sts get-caller-identity
                          echo "===== Checking existing stack ====="
                          STACK_STATUS=\$(aws cloudformation describe-stacks \\
                              --stack-name ${STACK_NAME} \\
                              --region \$REGION \\
                              --query "Stacks[0].StackStatus" \\
                              --output text 2>/dev/null || echo "NOT_FOUND")
                          echo "Stack status: \$STACK_STATUS"
                          # 🔥 Si el stack quedó roto, eliminarlo
                          if [ "\$STACK_STATUS" = "ROLLBACK_COMPLETE" ] || \\
                             [ "\$STACK_STATUS" = "CREATE_FAILED" ] || \\
                             [ "\$STACK_STATUS" = "UPDATE_ROLLBACK_COMPLETE" ]; then
                              echo "Deleting broken stack..."
                              aws cloudformation delete-stack \\
                                  --stack-name ${STACK_NAME} \\
                                  --region \$REGION
                              echo "Waiting stack deletion..."
                              aws cloudformation wait stack-delete-complete \\
                                  --stack-name ${STACK_NAME} \\
                                  --region \$REGION
                              echo "Stack deleted."
                          fi
                          echo "===== SAM Build ====="
                          sam build
                          echo "===== SAM Validate ====="
                          sam validate --region \$REGION
                          echo "===== SAM Deploy ====="
                      sam deploy --config-env production --no-fail-on-empty-changeset
                    """
        
        env.BASE_URL = sh(
                script: """
                    aws cloudformation describe-stacks \\
                      --stack-name ${STACK_NAME} \\
                      --region us-east-1 \\
                      --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" \\
                      --output text
                """,
                returnStdout: true
            ).trim()

            echo "BASE_URL = ${env.BASE_URL}"
        }
    }
        }
        stage('API Tests (pytest) - Read Only') {
            environment {
                BASE_URL = "${env.BASE_URL}"
            }
            steps{
                sh '''
                    python3 -m venv .venv
                    . .venv/bin/activate
                    
                    pip install pytest requests

                    # Solo ejecuta pruebas de lectura (sin modificar datos en producción)
                    pytest -v test/integration/todoApiReadOnlyTest.py --junitxml=result_unit.xml
                '''
                 junit 'result_unit.xml'
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}