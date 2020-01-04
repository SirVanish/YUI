using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;


class TestNeuralNet
{
    static void Main(string[] args)
    {
        // 0 0 0    => 0
        // 0 0 1    => 1
        // 0 1 0    => 1
        // 0 1 1    => 0
        // 1 0 0    => 1
        // 1 0 1    => 0
        // 1 1 0    => 0
        // 1 1 1    => 1

        NeuralNetwork net = new NeuralNetwork(new int[] { 3, 25, 25, 1 });

        //Itterate 5000 times and train each possible output
        //5000*8 = 40000 traning operations
        for (int i = 0; i < 5000; i++)
        {
            net.FeedForward(new float[] { 0, 0, 0 });
            net.BackProp(new float[] { 0 });

            net.FeedForward(new float[] { 0, 0, 1 });
            net.BackProp(new float[] { 1 });

            net.FeedForward(new float[] { 0, 1, 0 });
            net.BackProp(new float[] { 1 });

            net.FeedForward(new float[] { 0, 1, 1 });
            net.BackProp(new float[] { 0 });

            net.FeedForward(new float[] { 1, 0, 0 });
            net.BackProp(new float[] { 1 });

            net.FeedForward(new float[] { 1, 0, 1 });
            net.BackProp(new float[] { 0 });

            net.FeedForward(new float[] { 1, 1, 0 });
            net.BackProp(new float[] { 0 });

            net.FeedForward(new float[] { 1, 1, 1 });
            net.BackProp(new float[] { 1 });
        }

        Console.WriteLine(net.FeedForward(new float[] { 0, 0, 0 })[0]);
        Console.WriteLine(net.FeedForward(new float[] { 0, 0, 1 })[0]);
        Console.WriteLine(net.FeedForward(new float[] { 0, 1, 0 })[0]);
        Console.WriteLine(net.FeedForward(new float[] { 0, 1, 1 })[0]);
        Console.WriteLine(net.FeedForward(new float[] { 1, 0, 0 })[0]);
        Console.WriteLine(net.FeedForward(new float[] { 1, 0, 1 })[0]);
        Console.WriteLine(net.FeedForward(new float[] { 1, 1, 0 })[0]);
        Console.WriteLine(net.FeedForward(new float[] { 1, 1, 1 })[0]);

        //Console.WriteLine(Math.Round(net.FeedForward(new float[] { 0, 0, 0 })[0]));
        //Console.WriteLine(Math.Round(net.FeedForward(new float[] { 0, 0, 1 })[0]));
        //Console.WriteLine(Math.Round(net.FeedForward(new float[] { 0, 1, 0 })[0]));
        //Console.WriteLine(Math.Round(net.FeedForward(new float[] { 0, 1, 1 })[0]));
        //Console.WriteLine(Math.Round(net.FeedForward(new float[] { 1, 0, 0 })[0]));
        //Console.WriteLine(Math.Round(net.FeedForward(new float[] { 1, 0, 1 })[0]));
        //Console.WriteLine(Math.Round(net.FeedForward(new float[] { 1, 1, 0 })[0]));
        //Console.WriteLine(Math.Round(net.FeedForward(new float[] { 1, 1, 1 })[0]));

        Console.WriteLine("\nPress Enter to quit.");
        Console.ReadLine();
    }
}

