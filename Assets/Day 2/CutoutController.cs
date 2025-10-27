using UnityEngine;

public class CutoutController : MonoBehaviour
{
    public Material cutoutMaterial; // this is the material that will be cut with the object
    public GameObject cutter; // this is the provider of the location for the cutout
    public float cutoutRadius = 1f;
    
    void Update()
    {
        if (cutter != null && cutoutMaterial != null)
        {
            cutoutMaterial.SetVector("_CutoutLocation", cutter.transform.position);
            cutoutMaterial.SetFloat("_CutoutRadius", cutoutRadius);
        }
    }
}
