using Parameters

@with_kw struct InteriorJetSimulations
    f_0 = 1e-4
    Ny = 2^14
    Nz = 2^11
    Ly = 15_000 # m
    Lz = 500 # m
    νz = 1e-3
    sponge_frac = 1/16
    three_d = false

    JD15exp = (name = "JD15exp",
               f_0 = f_0,
               u_0 = 0.35e0,
               N2_inf = 4.9e-5,
               N2_pyc = 4.9e-5,
               Ny = Ny,
               Nz = Nz,
               Ly = 5000,
               Lz = Lz,
               σ_y = 1600,
               σ_z = 80,
               y_0 = Ly/2,
               z_0 = -Lz/2,
               νz = νz,
               sponge_frac = sponge_frac,
               )

    CIjet01 = (name = "CIintjet01",
               f_0 = f_0,
               u_0 = -0.4, # m/s
               N2_inf = 4e-5, # 1/s²
               N2_pyc = 4e-5, # 1/s²
               Ny = three_d ? Ny : 28*2^9,
               Nz = three_d ? Nz : 2^9,
               Ly = 12_000,
               Lz = Lz,
               σ_y = 1600, # m
               σ_z = 80, # m
               y_0 = 0.4 * 12_000, # m
               z_0 = -Lz/2, # m
               νz = νz,
               sponge_frac = sponge_frac,
               )

end


@with_kw struct SurfaceJetSimulations
    f_0 = 1e-4
    Ny = 10*2^9
    Nz = 2^9
    Ly = 15_000 # m
    Lz = 80 # m
    N2_pyc = 1e-6 # 1/s²
    νz=5e-4
    sponge_frac = 1/16
    ThreeD = false

    CIjet1 = (name = "CIsurfjet1",
              f_0 = f_0,
              u_0 = -0.2,
              N2_inf = 1e-5,
              N2_pyc = 1e-5,
              Ny = ThreeD ? Ny : 100*2^9,
              Nz = ThreeD ? Nz : 2^9,
              Ly = 8000,
              Lz = Lz,
              σ_y = 800,
              σ_z = 80,
              y_0 = +8000/2,
              z_0 = 0,
              νz = 5e-4,
              sponge_frac = sponge_frac,
             )

    CIjet2 = (name = "CIsurfjet2",
              f_0 = f_0,
              u_0 = -0.2,
              N2_inf = 5e-5,
              N2_pyc = 5e-5,
              Ny = Ny,
              Nz = Nz,
              Ly = Ly,
              Lz = Lz,
              σ_y = 800,
              σ_z = 80,
              y_0 = +Ly/2,
              z_0 = 0,
              νz = νz,
              sponge_frac = sponge_frac,
             )

    CIjet3 = (name = "CIsurfjet3",
              f_0 = f_0,
              u_0 = -0.2,
              N2_inf = 5e-6,
              N2_pyc = 5e-6,
              Ny = 2^15,
              Nz = 2^9,
              Ly = 15_000,
              Lz = 80,
              σ_y = 800,
              σ_z = 80,
              y_0 = +Ly/2,
              z_0 = 0,
              νz = 2e-4,
              sponge_frac = sponge_frac,
             )


    SIjet1 = (name = "SIsurfjet1",
              f_0 = f_0,
              u_0 = -0.2, # m/s
              N2_inf = 1e-5, # 1/s²
              Ny = ThreeD ? Ny : 100*2^9,
              Nz = ThreeD ? Nz : 2^9,
              Ly = 8000,
              Lz = Lz,
              σ_y = 1600, # m
              σ_z = 50, # m
              y_0 = +8000/2, # m
              z_0 = 0, # m
              N2_pyc = 1e-5,
              νz = νz,
              sponge_frac = sponge_frac,
              )

    SIjet2 = (name = "SIsurfjet2",
              f_0 = f_0,
              u_0 = -0.2,
              N2_inf = 1e-6,
              Ny = Ny,
              Nz = Nz,
              Ly = Ly,
              Lz = Lz,
              σ_y = 800,
              σ_z = 80,
              y_0 = +Ly/2,
              z_0 = 0,
              N2_pyc = 1e-6,
              νz = νz,
              sponge_frac = sponge_frac,
             )


    SIjet3 = (name = "SIsurfjet3",
              f_0 = f_0,
              u_0 = -0.2,
              N2_inf = 1e-6,
              Ny = Ny,
              Nz = Nz,
              Ly = Ly,
              Lz = Lz,
              σ_y = 1400,
              σ_z = 80,
              y_0 = +Ly/2,
              z_0 = 0,
              N2_pyc = 1e-6,
              νz = 8e-4,
              sponge_frac = sponge_frac,
             )



    SIjet4 = (name = "SIsurfjet4",
              f_0 = f_0,
              u_0 = -0.2,
              N2_inf = 1e-6,
              Ny = ThreeD ? Ny : 100*2^9,
              Nz = ThreeD ? Nz : 2^9,
              Ly = 8000,
              Lz = Lz,
              σ_y = 1600,
              σ_z = 80,
              y_0 = +4000,
              z_0 = 0,
              N2_pyc = 1e-6,
              νz = 5e-4,
              sponge_frac = sponge_frac,
             )



    SIjet5 = (name = "SIsurfjet5",
              f_0 = f_0,
              u_0 = -0.1,
              N2_inf = 2.5e-7,
              Ny = Ny,
              Nz = Nz,
              Ly = Ly,
              Lz = Lz,
              σ_y = 800,
              σ_z = 80,
              y_0 = +Ly/2,
              z_0 = 0,
              N2_pyc = 2.5e-7,
              νz = 1e-3,
              sponge_frac = sponge_frac,
              )



    SIjet6 = (name = "SIsurfjet6",
              f_0 = f_0,
              u_0 = -0.2,
              N2_inf = 2.5e-6,
              Ny = Ny,
              Nz = Nz,
              Ly = Ly,
              Lz = Lz,
              σ_y = 1200,
              σ_z = 80,
              y_0 = +Ly/2,
              z_0 = 0,
              N2_pyc = 2.5e-6,
              νz = νz,
              sponge_frac = sponge_frac,
              )



    Stabjet1 = (name = "Stabsurfjet1",
                f_0 = f_0,
                u_0 = -0.08,
                N2_inf = 1e-5,
                Ny = Ny,
                Nz = Nz,
                Ly = Ly,
                Lz = Lz,
                σ_y = 1600,
                σ_z = 80,
                y_0 = +Ly/2,
                z_0 = 0,
                N2_pyc = 1e-5,
                νz = νz,
                sponge_frac = 1/32,
                )


    Sloshjet1 = (name = "Sloshsurfjet1",
                f_0 = f_0,
                u_0 = -0.08,
                N2_inf = 1e-5,
                Ny = Ny,
                Nz = Nz,
                Ly = Ly,
                Lz = Lz,
                σ_y = 1600,
                σ_z = 80,
                y_0 = +Ly/2,
                z_0 = 0,
                N2_pyc = 1e-5,
                νz = νz,
                sponge_frac = 1/32,
                )


end

