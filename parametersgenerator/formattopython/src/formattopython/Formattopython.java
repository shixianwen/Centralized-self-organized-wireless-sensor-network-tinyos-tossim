/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package formattopython;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

/**
 *
 * @author wens
 */
public class Formattopython {

    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) {
        // TODO code application logic here
        File file = new File("linkout.txt");
        File filew = new File("linkoutconverted.txt");
        try {
            FileReader inOne = new FileReader(file);
            BufferedReader inTwo = new BufferedReader(inOne);
            FileWriter outOne1 = new FileWriter(filew);
            BufferedWriter outTwo1 = new BufferedWriter(outOne1);
            String s1 = null;
            String s2 = null;
            String temp = null;
            double oldgain=-300;
            int length =0;
            double gain;
            int k=1;
            while ((s1 = inTwo.readLine()) != null) {
                System.out.println(s1);
                if (s1.startsWith("gain")) {
                    s1 = s1.substring(5);
                    length= s1.length();
                    s2 = s1.substring(length-7, length);
                    System.out.println(s1);
                    System.out.println("s2="+s2);
                    gain = Double.parseDouble(s2);
                    if((k%2)==1)
                    {   
                        temp = s1;
                        oldgain = gain;
                    }
                    System.out.println(gain);
                    if((gain>-90)&&(oldgain>-90)&&(k%2==0)){
                    outTwo1.write(temp);
                    outTwo1.newLine();
                    outTwo1.write(s1);
                    outTwo1.newLine();
                    outTwo1.flush();}
                    k++;
                }
                    
                }
                inTwo.close();
                inOne.close();
                outTwo1.close();
                outOne1.close();
            }catch(IOException e){
            System.out.println(e);
        }
        }

    }
