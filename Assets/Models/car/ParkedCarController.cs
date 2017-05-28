using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ParkedCarController : MonoBehaviour {
    private Rigidbody rigid;
    public MeshRenderer mesh;

	// Use this for initialization
	void Start () {
        rigid = GetComponent<Rigidbody>();

        mesh.material.color = Random.ColorHSV(0f, 1f, 0f, 0f, 0.1f, 1f);
        if (mesh.material.color.grayscale > 0.3f && mesh.material.color.grayscale < 0.7f)
        {
            mesh.material.color = Random.ColorHSV(0f, .7f, 1f, 1f, .8f, 1.0f);
        }
        
    }
	
	// Update is called once per frame
	void FixedUpdate () {
        //simulate wheels/drag
        Vector3 vel = transform.InverseTransformVector(rigid.velocity);
        float x = vel.x * 0.95f;
        float y = vel.y;
        float z = vel.z;
        rigid.velocity = transform.TransformVector(new Vector3(x, y, z));
    }
}
