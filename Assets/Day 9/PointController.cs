using System.Collections.Generic;
using UnityEngine;

public class PointController : MonoBehaviour
{
    public GameObject pointPrefab;
    public Transform spawnPoint;
    public Material raymarchMaterial;

    public List<Rigidbody> points = new List<Rigidbody>();
    public Vector4[] pointPositions = new Vector4[32];

    public void Start()
    {
        foreach(var point in points)
        {
            ResetPoint(point);
        }
    }
    
    public void Update()
    {
        foreach (var point in points)
        {
            if (point.transform.position.y < -2f)
            {
                Vector3 randomOffset = new Vector3(Random.Range(-.25f, .25f), Random.Range(-.25f, .25f), Random.Range(-.25f, .25f));
                point.position = spawnPoint.position + randomOffset;
                point.linearVelocity = Vector3.zero;
            }
        }

        SetMaterialProperties();
    }

    private void SetMaterialProperties()
    {
        for (int i = 0; i < points.Count; i++)
        {
            pointPositions[i] = points[i].position;
        }
        raymarchMaterial.SetVectorArray("_points", pointPositions);
        
    }

    private void ResetPoint(Rigidbody point)
    {
        Vector3 randomOffset = new Vector3(Random.Range(-1.25f, 1.25f), Random.Range(-1.25f, 1.25f), Random.Range(-1.25f, 1.25f));
        point.position = spawnPoint.position + randomOffset;
        point.linearVelocity = Vector3.zero;
        // add force in a random direction
        Vector3 randomForce = new Vector3(Random.Range(-1f, 1f), Random.Range(-1f, 1f), Random.Range(-1f, 1f)).normalized * Random.Range(.2f,2f);
        point.AddForce(randomForce, ForceMode.VelocityChange);
    }
    
    [ContextMenu("Create Points")]
    public void CreatePoints()
    {
        for (int i = 0; i < 32; i++)
        {
            Vector3 randomOffset = new Vector3(Random.Range(-1.25f, 1.25f), Random.Range(-1.25f, 1.25f), Random.Range(-1.25f, 1.25f));
            GameObject newPoint = Instantiate(pointPrefab, spawnPoint.position + randomOffset, Quaternion.identity);
            Rigidbody rb = newPoint.GetComponent<Rigidbody>();
            points.Add(rb);
        }
    }

    [ContextMenu("Clear Points")]
    public void ClearPoints()
    {
        points.ForEach(point => DestroyImmediate(point.gameObject));
        points.Clear();
    }
}
