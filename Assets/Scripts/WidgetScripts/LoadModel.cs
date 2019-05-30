using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LoadModel : MonoBehaviour
{
    public GameObject model;        // stores model as gameobject
    public bool randomizeModel;     // randomize model loading
    public string modelToLoad;      // string of the model specified to load

    public static List<string> modelList = new List<string> {
        "yui_casual" };

    // start is called before the first frame update
    void Start()
    {
        model = SelectModel();

        // instantiates the model
        GameObject.Instantiate(model, transform.position, transform.rotation);
    }

    // selects a model from a given string 
    // and returns it as a gameobject
    private GameObject SelectModel()
    {
        string prefab = "Prefabs/";
        string modelString = prefab + modelToLoad;

        // if no model to load is selected load 
        // the first model in modelList
        if (string.IsNullOrEmpty(modelToLoad))
            modelString = prefab + modelList[0];

        // randomize the selection of a model
        if (randomizeModel)
            modelString = prefab + RandomModel();

        return Resources.Load(modelString) as GameObject;
    }

    // get the random model
    private string RandomModel()
    {
        int index = (int)Random.Range(0, modelList.Count);
        return modelList[index];
    }
}
