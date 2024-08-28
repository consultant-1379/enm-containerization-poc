/*------------------------------------------------------------------------------
 *******************************************************************************
 * COPYRIGHT Ericsson 2016
 *
 * The copyright to the computer program(s) herein is the property of
 * Ericsson Inc. The programs may be used and/or copied only with written
 * permission from Ericsson Inc. or in accordance with the terms and
 * conditions stipulated in the agreement/contract under which the
 * program(s) have been supplied.
 *******************************************************************************
 *----------------------------------------------------------------------------*/
package com.ericsson.oss.itpf.jboss.jmsconfig.journal;

import java.io.File;

import org.hornetq.core.persistence.impl.journal.DescribeJournal;
import org.hornetq.core.server.impl.FileLockNodeManager;


public class PrintData // NO_UCD (unused code)
{
   public static void main(String[] arg)
   {
	  int errorCode=0;
      if (arg.length != 2)
      {
         System.err.println("Standalone Usage:\n java -cp hornetq-core.jar <bindings directory> <message directory>");
         System.err.println("\nMaven Usage:\n  cd hornetq-server && "
                               + "mvn -q exec:java -Dexec.args=\"/foo/hornetq/bindings /foo/hornetq/journal\" -Dexec.mainClass=\"org.hornetq.core.persistence.impl.journal.PrintData\"");
         System.exit(++errorCode);
      }

      File serverLockFile = new File(arg[1], "server.lock");

      if (serverLockFile.isFile())
      {
         try
         {
            FileLockNodeManager fileLock = new FileLockNodeManager(arg[1], false);
            fileLock.start();
            System.out.println("********************************************");
            System.out.println("Server's ID=" + fileLock.getNodeId().toString());
            System.out.println("********************************************");
            fileLock.stop();
         }
         catch (Exception e)
         {
            e.printStackTrace();
            errorCode=+3;
         }
      }

      System.out.println("********************************************");
      System.out.println("B I N D I N G S  J O U R N A L");
      System.out.println("********************************************");

      try
      {
         DescribeJournal.describeBindingsJournal(arg[0]);
      }
      catch (Exception e)
      {
         e.printStackTrace();
         errorCode=+5;
      }

      System.out.println("********************************************");
      System.out.println("M E S S A G E S   J O U R N A L");
      System.out.println("********************************************");

      try
      {
         DescribeJournal.describeMessagesJournal(arg[1]);
      }
      catch (Exception e)
      {
         e.printStackTrace();
         errorCode=+7;
      }
      if (errorCode > 0) {
      System.exit(errorCode);
      }
    }
}
